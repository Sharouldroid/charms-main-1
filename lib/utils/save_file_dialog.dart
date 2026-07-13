import 'dart:typed_data';
import 'save_file_dialog_stub.dart'
    if (dart.library.html) 'save_file_dialog_web.dart'
    if (dart.library.io) 'save_file_dialog_io.dart';

/// Prompts the user to choose a save location for [bytes] (io, via the
/// native "Save As" dialog) or triggers a browser download (web).
/// Returns the saved path on io, or [fileName] as a success sentinel on web
/// (browsers have no filesystem path and no cancel signal to report).
/// Returns null only when the user cancels the native io dialog.
Future<String?> saveFileWithDialog({
  required Uint8List bytes,
  required String fileName,
}) {
  return saveFileWithDialogImpl(bytes: bytes, fileName: fileName);
}
