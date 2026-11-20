import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'photo_transport.dart';
/*
  Handles byte stream coming from desktop serial input which would be the RPI data.
  Expects data is sent to [portName] port on the computer
*/
class SerialTransport implements PhotoTransport {
      
      final SerialPort port;
      late final SerialPortReader _reader;

      // portname e.g. "COM3"
      SerialTransport(String portName) 
      : port = SerialPort(portName) { // NOTE: this syntax just means the field 'port' is assigned b4 construction, necessary for a final variable
        // attempt to open
        if (!port.openRead()) {
          final available = SerialPort.availablePorts;
          throw Exception(
            'Failed to open $portName: ${SerialPort.lastError}. Available ports: ${available.isEmpty ? 'None found' : available.join(', ')}',
          );
        }
        _reader = SerialPortReader(port);
      }

      @override
      Stream<Uint8List> receive() {
        return _reader.stream;
      }
      void dispose() { // CLOSE PORT
        _reader.close();
        port.close();
        port.dispose();
      }
    }