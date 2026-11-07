import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'photo_transport.dart';
import 'transfer_metadata.dart';

/// Simulates incoming chunks by reading an existing photo from disk.
class MockTransport implements PhotoTransport {
  MockTransport({
    required this.sourceFile,
    this.chunkSize = 4096,
    this.chunkDelay = Duration.zero,
  }) {
    if (chunkSize <= 0) {
      throw ArgumentError.value(chunkSize, 'chunkSize', 'Must be positive.');
    }
  }

  final File sourceFile;
  final int chunkSize;
  final Duration chunkDelay;

  @override
  Stream<Uint8List> receive() async* {
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source photo does not exist', sourceFile.path);
    }

    // Step 1: Emit the 8-byte metadata header first
    final fileSize = await sourceFile.length();
    final extension = sourceFile.path.contains('.')
        ? sourceFile.path.split('.').last
        : 'jpg';

    final metadata = TransferMetadata(
      expectedBytes: fileSize,
      fileType: extension,
    );
    yield metadata.toBytes(); // send first

    if (chunkDelay > Duration.zero) {
      await Future<void>.delayed(chunkDelay);
    }

    // Step 2: Stream the photo payload in slices
    await for (final sourceChunk in sourceFile.openRead()) {
      final bytes = Uint8List.fromList(sourceChunk);

      for (var offset = 0; offset < bytes.length; offset += chunkSize) {
        final end = (offset + chunkSize < bytes.length)
            ? offset + chunkSize
            : bytes.length;
        // NOTE LAST CHUNK CAN BE SHORT

        yield Uint8List.fromList(bytes.sublist(offset, end));

        if (chunkDelay > Duration.zero) {
          await Future<void>.delayed(chunkDelay);
        }
      }
    }
  }
}
