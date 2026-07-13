import 'dart:typed_data';
import 'download_bytes_io.dart' show downloadBytesImpl;

Future<void> viewBytesImpl({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) {
  return downloadBytesImpl(bytes: bytes, fileName: fileName);
}
