import 'dart:typed_data';

Future<String?> saveFileWithDialogImpl({
  required Uint8List bytes,
  required String fileName,
}) async {
  throw UnsupportedError('Save-file dialog is not supported on this platform.');
}
