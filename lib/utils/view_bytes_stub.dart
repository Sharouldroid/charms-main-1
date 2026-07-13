import 'dart:typed_data';

Future<void> viewBytesImpl({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  throw UnsupportedError('File viewing is not supported on this platform.');
}
