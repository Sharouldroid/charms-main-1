import 'dart:typed_data';
import 'view_bytes_stub.dart'
    if (dart.library.html) 'view_bytes_web.dart'
    if (dart.library.io) 'view_bytes_io.dart';

/// Opens [bytes] in a new browser tab (web) or the platform's default
/// viewer app via a temp file (io). [mimeType] is only used on web.
Future<void> viewBytes({
  required Uint8List bytes,
  required String fileName,
  String mimeType = 'application/octet-stream',
}) {
  return viewBytesImpl(bytes: bytes, fileName: fileName, mimeType: mimeType);
}
