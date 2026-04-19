import 'dart:typed_data';

Future<void> savePdfImpl({
  required Uint8List bytes,
  required String fileName,
}) async {
  throw UnsupportedError('PDF download is not supported on this platform.');
}