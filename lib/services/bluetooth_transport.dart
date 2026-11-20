import 'dart:async';
import 'dart:typed_data';

import 'photo_transport.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
/*
  INPUT: not really input but has connection w paired device,
  accessible through RFCOMM input stream.
  Which sends: Uint8List byte chunks

  Needs to be passed using RPI connection,
  then will be passed into transfer_coordinator as PhotoTransport

  // this is roughly what we expect hardware to do?
  // the logic handling it should be in transfer_coordinator --> next step

  // important changes for use with android: should just send bytes over 
  // without checking length; no need to check header since it's handled in transfer_coordinator
*/
class BluetoothTransport implements PhotoTransport {
  BluetoothTransport({
    required this.connection,
    required this.sourceStream,
    required this.expectedBytes,
    this.chunkSize = 4096,
    this.chunkDelay = Duration.zero,
    this.fileType = 'jpg',
  }) {
    if (chunkSize <= 0) {
      throw ArgumentError.value(chunkSize, 'chunkSize', 'Must be positive.');
    }
    if (expectedBytes < 0) {
      throw ArgumentError.value(expectedBytes, 'expectedBytes', 'Must not be negative.');
    }
  }

  final BluetoothConnection connection;
  final Stream<Uint8List> sourceStream;
  final int expectedBytes;
  final String fileType;
  final int chunkSize;
  final Duration chunkDelay;

  @override
  Stream<Uint8List> receive() async* {
    // Listen for incoming Bluetooth data
    // and yield each received chunk.
    bool headerComplete = false;
    BytesBuilder header = BytesBuilder();
    await for (final chunk in connection.input!) { 
      if (!headerComplete) { 
        // construct from chunk (add from stream)
        final remaining = 8 - header.length;
        final headerBytes = chunk.take(remaining).toList(); // <= remaining
        header.add(headerBytes);
        if (header.length == 8) { 
          headerComplete = true;
          final first8 = header.toBytes();
          yield first8;
        } 
        if (chunk.length <= remaining) continue;
        // else
        yield chunk.sublist(remaining);
      } 
  
      else {
        yield Uint8List.fromList(chunk);
      } 
    } 

    // if improper number of bytes received or timeout, cut connection?
    // on other end

  }
}
