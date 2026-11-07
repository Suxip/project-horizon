# Photo receiver services

These files are transport-independent starter services for the Flutter photo-receiver prototype.

## Files

- `photo_transport.dart`: common interface for any source of incoming chunks.
- `mock_transport.dart`: reads an existing photo from disk and emits chunks.
- `photo_receiver.dart`: writes chunks incrementally to a destination file.

## Example usage

```dart
final transport = MockTransport(
  sourceFile: File('/path/to/original.jpg'),
  chunkSize: 4096,
  chunkDelay: const Duration(milliseconds: 2),
);

final receiver = PhotoReceiver();
final outputFile = File('/path/to/app-documents/received.jpg');

await receiver.startTransfer(
  destination: outputFile,
  expectedBytes: await File('/path/to/original.jpg').length(),
);

try {
  await for (final chunk in transport.receive()) {
    await receiver.receiveChunk(chunk);
    print('Progress: ${(receiver.progress * 100).toStringAsFixed(1)}%');
  }

  final receivedFile = await receiver.finishTransfer();
  print('Saved photo to: ${receivedFile.path}');
} catch (_) {
  await receiver.abortTransfer();
  rethrow;
}
```

Replace the example paths with paths appropriate to your app. In a Flutter app,
use `path_provider` to obtain an app-owned directory for the destination.

The mock transport and Bluetooth transport should both implement
`PhotoTransport`. The Bluetooth implementation will emit each received BLE
payload as a `Uint8List`.
