import 'dart:async';
import 'dart:typed_data';

import 'photo_transport.dart';

/*
  INPUT: not really input but has connection w paired device,
  accessible through RFCOMM input stream.
  Which sends: Uint8List byte chunks

  Needs to be passed using RPI connection,
  then will be passed into transfer_coordinator as PhotoTransport
*/
class BluetoothTransport implements PhotoTransport {
  @override
  Stream<Uint8List> receive() async* {
    // Listen for incoming Bluetooth data
    // and yield each received chunk.
    
    

  }
}
