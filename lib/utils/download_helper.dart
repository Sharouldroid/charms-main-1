import 'dart:typed_data';
import 'package:charms/utils/pdf_download.dart';

class DownloadHelper {
  static Future<void> downloadPdf({
    required Uint8List bytes,
    required String fileName,
  }) {
    return savePdf(bytes: bytes, fileName: fileName);
  }
}
