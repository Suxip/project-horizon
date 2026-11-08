# Project Horizon — Progress Summary (November 7, 2026)

## High-Level Overview
The focus so far was on transforming the photo transfer process from a prototype script into a clean, reliable, and modular pipeline, aligning action plans and designing a transfer protocol.

## 1. Built a Modular 3-Layer Streaming Pipeline
Instead of having one giant block of code handle receiving and saving photos, we divided the system into three specialized roles that work together like an assembly line:

1. **The Pipe (Transport)**:
   - Moves raw data chunks from the sender to the app.
   - It doesn't care whether the data comes from a test simulation, Bluetooth, or Wi-Fi.

2. **The Traffic Controller (Transfer Coordinator)**:
   - Reads a short 8-byte "label" (header) at the very front of the stream.
   - This label tells the app two essential facts before the payload begins: **how big the file is** and **what format it is** (e.g., PNG, JPG, or MP3).
   - Once it reads the label, it forwards only the pure file data to the storage writer and tracks overall progress (0% to 100%).

3. **The Safe Storage Writer (Photo Receiver)**:
   - Writes the incoming chunks directly onto the device's storage.
   - If the connection drops or fails midway, it automatically cancels and deletes the incomplete file so corrupted files don't clutter the device.

## 2. End-to-End System Context & Testing Strategy
Our architecture directly mirrors the complete two-way product loop: (but not integrated sending audio back yet)

```
[Phone A: Acting as RPI]                                  [Phone B: Horizon App]
 ┌──────────────────────┐                                 ┌───────────────────────┐
 │ 1. Camera / Photo    │ ─── 8-byte header + image ────> │ 2. TransferCoordinator│
 │                      │                                 │    (Saves to disk)    │
 │                      │ <──────── ACK (Receipt) ─────── │                       │
 │                      │                                 │ 3. AI / Vision Model  │
 │                      │                                 │    + Audio Gen (TTS)  │
 │ 5. Plays MP3 Audio   │ <─── 8-byte header + MP3 ────── │ 4. Audio Transport    │
 │    on Speaker        │ ──────── ACK (Receipt) ───────> │                       │
 └──────────────────────┘                                 └───────────────────────┘
```

### The Full Round Trip
1. **Images $\rightarrow$ App**: External hardware captures an image, streams bytes over Bluetooth to the Horizon App, and receives a confirmation of receipt (ACK).
2. **Processing**: The Horizon App processes the image through AI vision models and generates spoken guidance as an MP3 audio file. (FOR ML/HARDWARE?)
3. **Audio/Text $\rightarrow$ Hardware**: The Horizon App streams the MP3 audio back over Bluetooth to the hardware, which confirms receipt and plays the sound out loud. (TO BE IMPLEMENTED)

### The Testing Strategy ("Phone-as-RPI")
To iterate quickly without waiting for physical Raspberry Pi hardware:
- **Phone A (Simulated RPI)**: Acts as the Bluetooth peripheral and speaker. It picks an image, streams it over Bluetooth to Phone B, waits for the response, and plays the returned MP3.
- **Phone B (Horizon App Brain)**: Runs the Horizon app, manages image intake using today's `TransferCoordinator`, generates the audio, and sends it back.
- **Reusable Wire Contract**: Because our 8-byte header protocol (`TransferMetadata`) supports any 4-character format, the **exact same pipeline** handles incoming images (`'jpg'`, `'png'`) and outgoing audio responses (`'mp3'`).

## 3. Next Steps (`next.md`)
- **Displaying Receipt in the UI**: Showing proof of receipt on screen as soon as the transfer finishes, along with printing progress info to console.
- **Two-Phone Bluetooth Test**: Establishing the Bluetooth connection between Phone A (RPI simulator) and Phone B (Horizon App). ***IMPORTANT***
- **Receipt Acknowledgments (ACK)**: Adding lightweight confirmations in both directions ("Image Received OK", "Audio Received OK").
- **Audio Return Stream**: Hooking up the reverse pipe to deliver synthesized MP3 audio back to Phone A.
