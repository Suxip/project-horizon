# Project Horizon: Next Steps & Direction

## Executive Direction
With **Phase 2 (Transport-Independent Architecture)** completed and verified with unit tests, the core architecture is decoupled into three layers:
1. **Transport Layer** ([`PhotoTransport`](./lib/services/photo_transport.dart#L7)): Pure raw byte pipe.
2. **Coordinator Layer** ([`TransferCoordinator`](./lib/services/transfer_coordinator.dart#L10)): Strips the 8-byte [`TransferMetadata`](./lib/services/transfer_metadata.dart#L4) header and manages error auto-cleanup.
3. **Sink Layer** ([`PhotoReceiver`](./lib/services/photo_receiver.dart#L5)): Writes raw payload chunks directly to disk using native `dart:io`.

The next milestone focuses on **closing the visual loop in the UI** and **establishing the complete physical two-way round trip over Bluetooth Classic (RFCOMM / SPP)**:
- **Computer (Simulated RPI / Wearable Hardware)**: Streams test images to the app and receives/plays returned synthesized audio guidance through its speakers.
- **Android Phone (Horizon App Brain)**: Receives the image over Bluetooth Classic, saves to disk via [`PhotoReceiver`](./lib/services/photo_receiver.dart#L5), displays progress/image in the UI, and streams an MP3 response back over the same RFCOMM socket.

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

### 2. Forward Stream: Image Transfer (Computer -> Android Phone)
- [ ] **Pair Devices via OS Bluetooth**:
  - Pair the Android phone with the Computer in Windows / OS Bluetooth Settings to bind the RFCOMM serial COM port link.
- [ ] **2.1 Computer (Simulated RPI Sender)**:
  - Create a lightweight test script (Python using `pyserial` or `pybluez`) targeting the paired Bluetooth serial COM port (e.g. `COM3`):
    - Encodes 8-byte header via [`TransferMetadata`](./lib/services/transfer_metadata.dart#L4): 4 bytes big-endian file length + 4 bytes format (`b'jpg '` / `b'png '`).
    - Writes the 8-byte header first over the serial port.
    - Streams raw image bytes in consecutive chunks (4 KB – 16 KB buffers) at full RFCOMM bus speed (~2–3 Mbps).
- [ ] **2.2 Android Horizon App (Receiver / Sink)**:
  - Connect to the computer's paired Bluetooth device from the Horizon App (or accept incoming connection).
  - Pass [`BluetoothTransport`](./lib/services/bluetooth_transport.dart#L6) into [`TransferCoordinator.receivePhoto()`](./lib/services/transfer_coordinator.dart#L21).
  - [`PhotoReceiver`](./lib/services/photo_receiver.dart#L5) streams chunks directly into app storage via native `dart:io`.
  - Update UI progress indicator (`0%` to `100%`) as chunks arrive.
  - On completion, render the saved photo on screen and acknowledge receipt.

---

### 3. Return Stream: Audio Transfer & Playback (Android Phone -> Computer)
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
