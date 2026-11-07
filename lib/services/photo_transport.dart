import 'dart:typed_data';

/// A source of incoming photo bytes.
///
/// Both MockTransport and BluetoothTransport should implement this interface.
/// Each emitted Uint8List is one chunk; chunks must be emitted in order.
abstract interface class PhotoTransport {
  Stream<Uint8List> receive();
}
