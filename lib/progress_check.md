# Development Plan

## Phase 1: Mock Pipeline & UI Integration

- [x] Implement simulated sender that reads a local file (`MockTransport`).
- [x] Implement chunk slicing and streaming.
- [x] Implement disk writing in `PhotoReceiver`.
- [x] Implement transfer state management.
- [x] Test mock receiving pipeline in Android emulator.
- [x] Connect `MockTransport` to `PhotoReceiver` in the Flutter UI.
- [x] Add a button to trigger a simulated transfer.
- [ ] Display the received photo.
- [ ] Display transfer progress.
- [x] Handle incomplete and interrupted transfers.
- [x] Verify received photo matches the original byte-for-byte.

## Phase 2: Transport-Independent Architecture

- [x] Define `TransferMetadata` model (`expectedBytes`, `fileType`, binary 8-byte header). --> bytes 0-3 big-endian int32, bytes 4-7 extension e.g. png.
- [x] Define transport-agnostic wire framing (8-byte header + raw photo chunks).
- [x] Keep `PhotoTransport` as a pure, dumb byte-pipe interface (connection & raw byte delivery).
- [x] Separate connection lifecycle from data reception.
- [x] Implement `TransferCoordinator` to bridge `PhotoTransport` and `PhotoReceiver`.
- [x] Handle transfer completion, timeouts, and errors independently of transport (auto-cleanup on abort).
- [x] Update `MockTransport` to emit 8-byte `TransferMetadata` header first.
- [x] Add unit tests verifying `TransferCoordinator` and mock pipeline byte-for-byte.

## Future: Bluetooth Integration (BLE / Classic)

- [ ] Investigate iOS compatibility and choose BLE or Bluetooth Classic.
- [ ] Implement Android Bluetooth receiving functionality.
- [ ] Implement iOS Bluetooth sending functionality.
- [ ] Establish a connection between devices.
- [ ] Implement the corresponding `BluetoothTransport` conforming to the byte-pipe contract.
- [ ] Connect `BluetoothTransport` to `TransferCoordinator` & `PhotoReceiver`.
- [ ] Test photo transfer between physical devices.
