import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:charms/HRmodels/staff_document.dart';
import 'package:charms/HRproviders/staff_documents.dart';
import 'package:charms/HRwidgets/admin/hr_theme.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class StaffDocumentsAdminScreen extends StatefulWidget {
  final int staffId;
  final String staffName;

  const StaffDocumentsAdminScreen({
    super.key,
    required this.staffId,
    required this.staffName,
  });

  @override
  State<StaffDocumentsAdminScreen> createState() =>
      _StaffDocumentsAdminScreenState();
}

class _StaffDocumentsAdminScreenState
    extends State<StaffDocumentsAdminScreen> {
  static const Color _primaryBlue = Color(0xFF2563EB);

  static const Map<String, IconData> _typeIcons = {
    'Resume':          Icons.description_rounded,
    'Identity Card':   Icons.badge_rounded,
    'Bank Statement':  Icons.account_balance_rounded,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final docsProv = Provider.of<StaffDocuments>(context, listen: false);
    await docsProv.fetchSubmissions(widget.staffId);
    await docsProv.markViewed(widget.staffId);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _viewDocument(StaffDocument doc) async {
    final url = Uri.parse(
        'https://devcms.com.my/charmsAPI/public/storage/${doc.filePath}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not open document'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  Future<void> _downloadDocument(StaffDocument doc) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final url = Uri.parse(
          'https://devcms.com.my/charmsAPI/public/storage/${doc.filePath}');
      final res = await http.get(url);

      if (mounted) Navigator.of(context).pop();

      if (res.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Download failed (${res.statusCode})'),
            backgroundColor: Colors.redAccent,
          ));
        }
        return;
      }

      if (kIsWeb) {
        final blob = html.Blob([res.bodyBytes]);
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: blobUrl)
          ..setAttribute('download', doc.fileName)
          ..click();
        html.Url.revokeObjectUrl(blobUrl);
      } else {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/${doc.fileName}';
        await File(filePath).writeAsBytes(res.bodyBytes);
        await OpenFile.open(filePath);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Downloaded successfully'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Download error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HRColors.background,
      appBar: HRAppBar(title: '${widget.staffName} — Documents'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
          : RefreshIndicator(
              color: _primaryBlue,
              onRefresh: _load,
              child: Consumer<StaffDocuments>(
                builder: (context, docsProv, _) => HRPageContainer(
                  child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: StaffDocuments.documentTypes.map((type) {
                    final doc = docsProv.forType(type);
                    final uploaded = doc != null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: hrCardDecoration(radius: 14),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (uploaded ? Colors.teal : Colors.grey)
                                .withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                              _typeIcons[type] ?? Icons.insert_drive_file,
                              color: uploaded ? Colors.teal : Colors.grey,
                              size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(type,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                uploaded
                                    ? 'Uploaded${doc.submittedAt != null ? ' — ${DateFormat('dd MMM yyyy').format(doc.submittedAt!)}' : ''}'
                                    : 'Not uploaded yet',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: uploaded
                                        ? Colors.teal.shade700
                                        : Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        if (uploaded)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _viewDocument(doc),
                                icon: const Icon(
                                    Icons.visibility_outlined,
                                    size: 20),
                                tooltip: 'View',
                                color: _primaryBlue,
                              ),
                              IconButton(
                                onPressed: () => _downloadDocument(doc),
                                icon: const Icon(
                                    Icons.download_rounded,
                                    size: 20),
                                tooltip: 'Download',
                                color: Colors.teal,
                              ),
                            ],
                          ),
                      ]),
                    );
                  }).toList(),
                  ),
                ),
              ),
            ),
    );
  }
}
