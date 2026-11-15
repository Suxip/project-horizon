import 'dart:typed_data';

/// Minimal metadata describing an incoming photo transfer.
class TransferMetadata {
  TransferMetadata({
    required this.expectedBytes,
    required this.fileType,
  });

  /// Total number of photo payload bytes expected.
  final int expectedBytes;

  /// File extension without dot, e.g. 'jpg' or 'png'.
  final String fileType;

  /// Fixed header size in bytes on the wire.
  static const int headerSize = 8;

  /// Encodes this metadata into an 8-byte binary header:
  /// - Bytes 0..3: [expectedBytes] as a big-endian uint32.
  /// - Bytes 4..7: [fileType] as 4 ASCII characters (padded with null bytes on left).
  Uint8List toBytes() {
    final buffer = Uint8List(headerSize);
    final bdata = ByteData.sublistView(buffer);
    bdata.setUint32(0, expectedBytes);

    final cleanType = fileType.replaceAll('.', '').toLowerCase();
    final typeUnits = cleanType.codeUnits;
    for (var i = 0; i < typeUnits.length && i < 4; i++) {
      buffer[4 + i] = typeUnits[i];
    }
    return buffer;
  }

  /// Decodes metadata from an 8-byte binary header.
  factory TransferMetadata.fromBytes(Uint8List bytes) {
    if (bytes.length < headerSize) {
      throw ArgumentError('Header must be at least $headerSize bytes, received ${bytes.length}.');
    }
    final bdata = ByteData.sublistView(bytes);
    final expectedBytes = bdata.getUint32(0); // expects big-endian

    final fileType = String.fromCharCodes(bytes.sublist(4, 8))
        .replaceAll('\x00', '')
        .trim();

    return TransferMetadata(
      expectedBytes: expectedBytes,
      fileType: fileType.isEmpty ? 'jpg' : fileType,
    );
  }
}
