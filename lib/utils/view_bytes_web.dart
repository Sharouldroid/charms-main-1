import 'dart:typed_data';
import 'dart:html' as html;

Future<void> viewBytesImpl({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.window.open(url, '_blank');

  Future.delayed(const Duration(seconds: 10), () {
    html.Url.revokeObjectUrl(url);
  });
}
