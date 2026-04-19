import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';

// web-only imports (allowed with ignore)
import 'dart:html' as html; // ignore: avoid_web_libraries_in_flutter

class DownloadHelper {
  static Future<void> downloadPdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      return;
    }

    // mobile/desktop fallback
    await Printing.layoutPdf(
      name: fileName,
      onLayout: (_) async => bytes,
    );
  }
}