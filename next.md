# Project Horizon: Next Steps & Direction

## Executive Direction
With **Phase 2 (Transport-Independent Architecture)** completed and verified with unit tests, the core architecture is decoupled into three layers:
1. **Transport Layer** ([`PhotoTransport`](./lib/services/photo_transport.dart#L7)): Pure raw byte pipe.
2. **Coordinator Layer** ([`TransferCoordinator`](./lib/services/transfer_coordinator.dart#L10)): Strips the 8-byte [`TransferMetadata`](./lib/services/transfer_metadata.dart#L4) header and manages error auto-cleanup.
3. **Sink Layer** ([`PhotoReceiver`](./lib/services/photo_receiver.dart#L5)): Writes raw payload chunks directly to disk using native `dart:io`.

The next milestone focuses on **closing the visual loop in the UI** and **establishing the complete physical two-way round trip over Bluetooth Classic (RFCOMM / SPP)**:
- **Raspberry Pi (Wearable Hardware)**: Captures/reads test images, streams them over Bluetooth Classic RFCOMM to the computer, and receives/plays returned synthesized audio guidance through attached speakers/headphones.
- **Computer (Horizon App Desktop)**: Receives the image over the incoming Bluetooth serial COM port, saves to disk via [`PhotoReceiver`](./lib/services/photo_receiver.dart#L5), displays progress and rendered image in the desktop UI, and streams an MP3 response back over the serial pipe.

---

## Potential Actionable To-Do List

### 0. Optional UI Integration & Visual Verification (Phase 1 Cleanup)
- [ ] **Clean Mock Demo**:
  - Add a toggle/button to run a simulated mock transfer from `lib/images/sample.jpg` / `sample.png`.
- [ ] **Display Transfer Progress**:
  - Hook the `onProgress` callback to a `LinearProgressIndicator` widget in [main.dart](./lib/main.dart).
- [ ] **Display Received Image & Receipt Status**:
  - Render the completed `File` on screen via `Image.file` upon successful receipt.

---

### 1. Bluetooth Classic Infrastructure Setup (RFCOMM / SPP)
- [ ] **Configure Android Bluetooth Permissions**:
  - Add `BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_CONNECT`, and `BLUETOOTH_SCAN` permissions to `android/app/src/main/AndroidManifest.xml`.
- [ ] **Standard Serial Port Profile (SPP) UUID**:
  - Adopt standard Bluetooth Classic SPP UUID:
    - `SPP_UUID`: `00001101-0000-1000-8000-00805F9B34FB`
- [ ] **Add Bluetooth Classic Package / Channel**:
  - Add `flutter_bluetooth_serial` to `pubspec.yaml` (or implement a lightweight Android `MethodChannel` wrapping `BluetoothSocket` / `BluetoothServerSocket`). <!-- Need to ensure secure method is used here, flutter_bluetooth_serial prioritizes device compatibility; can do security later but during testing turn off discoverable mode for BT after pairing as safety measure -->
- [ ] **Implement `BluetoothTransport`**:
  - Implement [`BluetoothTransport`](./lib/services/bluetooth_transport.dart#L6) implementing [`PhotoTransport`](./lib/services/photo_transport.dart#L7), wrapping the RFCOMM `InputStream` (`connection.input`) and yielding incoming `Uint8List` byte chunks.

---

### 2. Forward Stream: Image Transfer (Raspberry Pi -> Computer [Horizon App])
- [ ] **Pair Devices via OS Bluetooth & Assign COM Port**:
  - Pair the Raspberry Pi with the Computer via Bluetooth settings.
  - On the Computer (Windows/Desktop), configure an incoming Bluetooth Serial Port (SPP) bound to a virtual COM port (e.g., `COM3`, `COM4` under *Bluetooth Settings -> COM Ports*).
  - On the Raspberry Pi, verify the paired device link via `bluetoothctl` or RFCOMM bind (`rfcomm bind 0 <PC_MAC_ADDRESS>`).
- [ ] **2.1 Raspberry Pi (Hardware Sender)**:
  - Create a sender script on the RPI (Python using `pybluez` or `pyserial` on `/dev/rfcomm0`):
    - Reads sample test image (or captures from Pi camera module via `picamera2`/`libcamera`).
    - Encodes the 8-byte header via [`TransferMetadata`](./lib/services/transfer_metadata.dart#L4): 4 bytes big-endian length (`struct.pack('>I', size)`) + 4 ASCII bytes format (`b'jpg '` / `b'png '`).
    - Writes the 8-byte header first over the RFCOMM socket / serial port.
    - Streams raw image bytes sequentially in chunks (4 KB – 16 KB buffers).
- [ ] **2.2 Computer Horizon App (Desktop Receiver / Sink)**:
  - Implement desktop serial transport (e.g. `SerialTransport` implementing [`PhotoTransport`](./lib/services/photo_transport.dart#L7) using `flutter_libserialport` or Windows serial stream listening on the designated `COM` port).
  <!--Rework will be necessary if stream is to be held open: idea to use ACK signal to note end of transmission and it will check if received bytes is correct, else send failed notification and keep going -->
  - Pass the transport into [`TransferCoordinator.receivePhoto()`](./lib/services/transfer_coordinator.dart#L21).
  - Stream chunks directly to local storage via [`PhotoReceiver`](./lib/services/photo_receiver.dart#L5) using native `dart:io`.
  - Update desktop UI progress indicator (`0%` to `100%`) in real-time as chunks arrive.
  - On completion, render the saved photo on screen (`Image.file`) and display throughput statistics. OPTIONALLY.

---

### 3. Return Stream: Audio Transfer & Playback (Android Phone -> Computer) (NEEDS update to be computer later android phone to rpi)
- [ ] **3.1 Symmetric Wire Protocol for Audio**:
  - Reuse the identical 8-byte header structure for audio responses:
    - Encodes 4-byte big-endian length + 4-byte format (`"mp3 "`):
      [`TransferMetadata`](./lib/services/transfer_metadata.dart#L4)`(expectedBytes: audioBytes.length, fileType: "mp3").toBytes()`.
- [ ] **3.2 Android Audio Sender**:
  - Add an audio sender service/method in the app (e.g. `AudioSender.sendAudio(...)`).
  - Read sample response audio (e.g. asset `lib/audio/response.mp3` or generated TTS file).
  - Write the 8-byte header followed by the raw MP3 byte chunks directly to the open RFCOMM `connection.output`.
- [ ] **3.3 Computer Audio Receiver & Speaker Playback (Simulated RPI Speaker)**:
  - Extend the Computer Python script to keep the serial port open and listen for the return stream:
    - Unpacks the 8-byte metadata header (`expectedBytes`, format `mp3`).
    - Receives incoming MP3 byte stream until `expectedBytes` are received.
    - Saves bytes to a temporary audio file and immediately plays it aloud via computer speakers (using `pygame`, `playsound`, or system media player).
    - Logs round-trip latency and transfer completion confirmation.

---

### 4. Robustness & Production Hardening
- [ ] **Throughput & Buffer Tuning**:
  - Tune chunk buffer sizes (4 KB – 16 KB) for optimal throughput across Bluetooth Classic without overwhelming memory.
- [ ] **Connection Drop & Auto-Cleanup**:
  - Verify [`PhotoReceiver.abortTransfer()`](./lib/services/photo_receiver.dart#L86) properly deletes incomplete image files if RFCOMM drops mid-stream.
  - Implement connection state observers and auto-reconnect in [`BluetoothTransport`](./lib/services/bluetooth_transport.dart#L6).
- [ ] **Full-Duplex Flow Control & Stream Hand-off**:
  - Ensure the RFCOMM socket cleanly transitions between receiving image data and transmitting audio responses without stream buffer deadlocks.
- [ ] **Wire Header Validation**:
  - Verify rejection and error handling if header length declares invalid sizes or unsupported extensions.
