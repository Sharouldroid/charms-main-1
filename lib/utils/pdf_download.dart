import 'dart:typed_data';
import 'pdf_download_stub.dart'
    if (dart.library.html) 'pdf_download_web.dart'
    if (dart.library.io) 'pdf_download_io.dart';

Future<void> savePdf({
  required Uint8List bytes,
  required String fileName,
}) {
  return savePdfImpl(bytes: bytes, fileName: fileName);
}