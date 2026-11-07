import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'photo_transport.dart';

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
  Stream<Uint8List> receive() async* { // Output here is processed in receiver 
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source photo does not exist', sourceFile.path);
    }

    // File.openRead() streams the source rather than loading the whole photo.
    await for (final sourceChunk in sourceFile.openRead()) {
      // File.openRead() yields List<int>; normalize it to Uint8List.
      final bytes = Uint8List.fromList(sourceChunk);

      for (var offset = 0; offset < bytes.length; offset += chunkSize) {
        final end = (offset + chunkSize < bytes.length)
            ? offset + chunkSize
            : bytes.length;

        // Copy this slice so each emitted chunk is an independent byte array.
        yield Uint8List.fromList(bytes.sublist(offset, end));

        if (chunkDelay > Duration.zero) { // wait
          await Future<void>.delayed(chunkDelay);
        }
      }
    }
  }
}
