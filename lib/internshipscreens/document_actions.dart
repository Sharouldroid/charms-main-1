import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charms/main.dart';
import 'package:charms/utils/download_bytes.dart';
import 'package:charms/utils/view_bytes.dart';

/// Shared view/download actions for internship document submissions.
/// Used by both the admin submissions list and the intern detail screen
/// so the two stay in sync instead of maintaining duplicate blob logic.
class DocumentActions {
  static Future<void> downloadFile(
    BuildContext context,
    int submissionId,
    String fileName,
  ) async {
    try {
      _showLoadingDialog(context, 'Downloading file...');

      final response = await http.get(
        Uri.parse(
            '${AppConfig.hostname}/api/internship/documents/download/$submissionId'),
      );

      if (context.mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        await downloadBytes(bytes: response.bodyBytes, fileName: fileName);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (context.mounted) {
        _showError(context, 'Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showError(context, 'Error downloading file: $e');
      }
    }
  }

  static Future<void> viewFile(
    BuildContext context,
    int submissionId,
    String fileName,
  ) async {
    try {
      _showLoadingDialog(context, 'Opening file...');

      final response = await http.get(
        Uri.parse(
            '${AppConfig.hostname}/api/internship/documents/download/$submissionId'),
      );

      if (context.mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        String mimeType = 'application/octet-stream';
        final lower = fileName.toLowerCase();
        if (lower.endsWith('.pdf')) {
          mimeType = 'application/pdf';
        } else if (lower.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
          mimeType = 'image/jpeg';
        } else if (lower.endsWith('.webp')) {
          mimeType = 'image/webp';
        }

        await viewBytes(
          bytes: response.bodyBytes,
          fileName: fileName,
          mimeType: mimeType,
        );
      } else if (context.mounted) {
        _showError(context, 'Failed to open file: ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showError(context, 'Error opening file: $e');
      }
    }
  }

  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
