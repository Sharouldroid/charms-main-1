import 'dart:typed_data';
import 'download_bytes_stub.dart'
    if (dart.library.html) 'download_bytes_web.dart'
    if (dart.library.io) 'download_bytes_io.dart';

/// Saves [bytes] as [fileName] to the browser downloads folder (web) or a
/// temp file that is then opened with the platform's default viewer (io).
Future<void> downloadBytes({
  required Uint8List bytes,
  required String fileName,
}) {
  return downloadBytesImpl(bytes: bytes, fileName: fileName);
}
