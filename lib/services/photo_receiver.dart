import 'dart:io';
import 'dart:typed_data';

/// Writes incoming chunks directly to a destination file.
class PhotoReceiver {
  RandomAccessFile? _output;
  File? _destination;
  int _expectedBytes = 0;
  int _receivedBytes = 0;

  bool get isReceiving => _output != null;
  int get receivedBytes => _receivedBytes;
  int get expectedBytes => _expectedBytes;

  double get progress {
    if (_expectedBytes <= 0) return 0;
    return (_receivedBytes / _expectedBytes).clamp(0.0, 1.0);
  }

  /// Starts a transfer and opens [destination] for writing.
  Future<void> startTransfer({
    required File destination,
    required int expectedBytes, // From sender; In testing, == await source.length()
    int maxFileBytes = 20 * 1024 * 1024,
  }) async {
    if (isReceiving) {
      throw StateError('A transfer is already in progress.');
    }
    if (expectedBytes <= 0 || expectedBytes > maxFileBytes) {
      throw ArgumentError.value(
        expectedBytes,
        'expectedBytes',
        'Must be between 1 and $maxFileBytes bytes.',
      );
    }

    await destination.parent.create(recursive: true);

    _destination = destination;
    _expectedBytes = expectedBytes;
    _receivedBytes = 0;
    _output = await destination.open(mode: FileMode.write);
  }

  /// Writes one incoming chunk to disk.
  Future<void> receiveChunk(Uint8List chunk) async {
    final output = _output;
    if (output == null) {
      throw StateError('Call startTransfer() before receiving chunks.');
    }
    if (_receivedBytes + chunk.length > _expectedBytes) {
      throw StateError('Received more bytes than the transfer declared.');
    }

    await output.writeFrom(chunk);
    _receivedBytes += chunk.length;
  }

  /// Flushes/closes the file and returns it once the expected size is reached.
  Future<File> finishTransfer() async {
    // Throws Exceptions for failed or incomplete transfer
    final output = _output;
    final destination = _destination;

    if (output == null || destination == null) {
      throw StateError('No transfer is in progress.');
    }
    if (_receivedBytes != _expectedBytes) {
      throw StateError(
        'Transfer incomplete: received $_receivedBytes of $_expectedBytes bytes.',
      );
    }

    await output.flush();
    await output.close();

    _output = null;
    _destination = null;
    _expectedBytes = 0;
    _receivedBytes = 0;

    return destination;
  }

  /// Closes the current file and deletes the incomplete output, if possible.
  Future<void> abortTransfer() async {
    final output = _output;
    final destination = _destination;

    _output = null;
    _destination = null;
    _expectedBytes = 0;
    _receivedBytes = 0;

    if (output != null) {
      await output.close();
    }
    if (destination != null && await destination.exists()) {
      await destination.delete();
    }
  }
}
