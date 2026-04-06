import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

Future<void> uploadFile(int userId) async {
  FilePickerResult? result = await FilePicker.platform
      .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
  if (result != null) {
    File file = File(result.files.single.path!);
    var request = http.MultipartRequest(
        'POST', Uri.parse('http://localhost/internship1/upload.php'));
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    request.fields['userId'] = userId.toString(); // Include user ID
    var response = await request.send();

    if (response.statusCode == 200) {
      print('File uploaded successfully');
    } else {
      print('Failed to upload file');
    }
  }
}
