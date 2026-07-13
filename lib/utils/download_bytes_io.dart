import 'dart:io';
import 'dart:typed_data';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

Future<void> downloadBytesImpl({
  required Uint8List bytes,
  required String fileName,
}) async {
  final tempDir = await getTemporaryDirectory();
  final filePath = '${tempDir.path}/$fileName';
  await File(filePath).writeAsBytes(bytes);
  await OpenFile.open(filePath);
}
