import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_horizon_app/services/mock_transport.dart';
import 'package:project_horizon_app/services/photo_transport.dart';
import 'package:project_horizon_app/services/transfer_coordinator.dart';
import 'package:project_horizon_app/services/transfer_metadata.dart';

class _FailingTransport implements PhotoTransport {
  @override
  Stream<Uint8List> receive() async* {
    yield TransferMetadata(expectedBytes: 100, fileType: 'jpg').toBytes();
    yield Uint8List.fromList([1, 2, 3]);
    throw const SocketException('Connection lost');
  }
}

void main() {
  group('TransferMetadata', () {
    test('encodes and decodes 8-byte header correctly', () {
      final original = TransferMetadata(expectedBytes: 4096, fileType: 'png');
      final bytes = original.toBytes();

      expect(bytes.length, equals(8));

      final decoded = TransferMetadata.fromBytes(bytes);
      expect(decoded.expectedBytes, equals(4096));
      expect(decoded.fileType, equals('png'));
    });
  });

  group('TransferCoordinator', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('transfer_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('successfully transfers and saves photo byte-for-byte using MockTransport', () async {
      // Create a test file
      final sourceFile = File('${tempDir.path}/source.jpg');
      final sourceBytes = Uint8List.fromList(List.generate(1024, (i) => i % 256));
      await sourceFile.writeAsBytes(sourceBytes);

      final mockTransport = MockTransport(
        sourceFile: sourceFile,
        chunkSize: 128,
      );

      final coordinator = TransferCoordinator();
      final progressUpdates = <double>[];

      final destinationFile = await coordinator.receivePhoto(
        transport: mockTransport,
        saveDirectory: tempDir,
        onProgress: (p) => progressUpdates.add(p),
      );

      expect(await destinationFile.exists(), isTrue);
      expect(destinationFile.path.endsWith('.jpg'), isTrue);

      final receivedBytes = await destinationFile.readAsBytes();
      expect(receivedBytes, equals(sourceBytes));

      expect(progressUpdates.isNotEmpty, isTrue);
      expect(progressUpdates.last, equals(1.0));
    });

    test('aborts and cleans up destination file on stream failure', () async {
      final coordinator = TransferCoordinator();

      expect(
        () => coordinator.receivePhoto(
          transport: _FailingTransport(),
          saveDirectory: tempDir,
        ),
        throwsA(isA<SocketException>()),
      );

      // Verify no incomplete files remain in the temp directory
      final files = await tempDir.list().toList();
      expect(files.isEmpty, isTrue);
    });
  });
}
