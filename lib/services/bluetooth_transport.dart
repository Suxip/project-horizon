import 'dart:async';
import 'dart:typed_data';

import 'photo_transport.dart';

class BluetoothTransport implements PhotoTransport {
  @override
  Stream<Uint8List> receive() async* {
    // Listen for incoming Bluetooth data
    // and yield each received chunk.
    // to be implemented
  }
}
