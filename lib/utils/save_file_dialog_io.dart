import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> saveFileWithDialogImpl({
  required Uint8List bytes,
  required String fileName,
}) async {
  final tempDir = await getTemporaryDirectory();
  final tempFilePath = '${tempDir.path}/$fileName';
  final file = File(tempFilePath);
  await file.writeAsBytes(bytes);

  final params = SaveFileDialogParams(sourceFilePath: file.path);
  return FlutterFileDialog.saveFile(params: params);
}
