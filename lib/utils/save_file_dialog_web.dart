import 'dart:typed_data';
import 'download_bytes_web.dart' show downloadBytesImpl;

Future<String?> saveFileWithDialogImpl({
  required Uint8List bytes,
  required String fileName,
}) async {
  await downloadBytesImpl(bytes: bytes, fileName: fileName);
  return fileName;
}
