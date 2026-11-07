import 'dart:io';
import 'dart:typed_data';

import 'photo_receiver.dart';
import 'photo_transport.dart';
import 'transfer_metadata.dart';

/// Bridges any [PhotoTransport] to a [PhotoReceiver].
///
/// Unpacks the initial 8-byte [TransferMetadata] header from the incoming byte
/// stream, initializes the [PhotoReceiver], streams the remaining payload
/// chunks to disk, and automatically cleans up if an error or disconnect occurs.
class TransferCoordinator {
  TransferCoordinator({PhotoReceiver? receiver})
      : _receiver = receiver ?? PhotoReceiver();

  final PhotoReceiver _receiver;

  /// Listens to [transport], writes incoming photo chunks to [saveDirectory],
  /// and returns the completed [File].
  Future<File> receivePhoto({
    required PhotoTransport transport,
    required Directory saveDirectory,
    void Function(double progress)? onProgress, // e.g. print statement after chunk receipt
  }) async {
    final buffer = BytesBuilder(copy: false);
    TransferMetadata? metadata;

    try {
      await for (final chunk in transport.receive()) {
        if (chunk.isEmpty) continue;

        // Step 1: Accumulate and parse the 8-byte metadata header first
        if (metadata == null) {
          buffer.add(chunk);
          if (buffer.length < TransferMetadata.headerSize) {
            continue; // Wait until we have at least 8 bytes for the header
          }

          final allBytes = buffer.takeBytes();
          final headerBytes = Uint8List.sublistView( // here allBytes >= headersize
            allBytes,
            0,
            TransferMetadata.headerSize,
          );
          metadata = TransferMetadata.fromBytes(headerBytes);

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final destFile = File(
            '${saveDirectory.path}/received_$timestamp.${metadata.fileType}',
          );

          await _receiver.startTransfer( // header is not written to receiver
            destination: destFile,
            expectedBytes: metadata.expectedBytes,
          );

          // If the first chunk contained payload bytes beyond the 8-byte header:
          if (allBytes.length > TransferMetadata.headerSize) {
            final leftover = Uint8List.sublistView(
              allBytes,
              TransferMetadata.headerSize, // start
            );
            await _receiver.receiveChunk(leftover);
            onProgress?.call(_receiver.progress);
          }
        } else {
          // Step 2: Feed subsequent payload chunks directly to PhotoReceiver
          await _receiver.receiveChunk(chunk);
          onProgress?.call(_receiver.progress);
        }
      }

      if (metadata == null) {
        throw StateError('Stream closed before receiving transfer metadata header.');
      }

      // Step 3: Finish and return the saved file
      return await _receiver.finishTransfer();
    } catch (e) {
      // Clean up incomplete file on any stream error or abort
      await _receiver.abortTransfer();
      rethrow;
    }
  }
}
