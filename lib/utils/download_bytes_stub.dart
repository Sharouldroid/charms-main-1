import 'dart:typed_data';

Future<void> downloadBytesImpl({
  required Uint8List bytes,
  required String fileName,
}) async {
  throw UnsupportedError('File download is not supported on this platform.');
}
