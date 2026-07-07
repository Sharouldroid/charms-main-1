import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:charms/HRmodels/staff_document.dart';
import 'package:charms/HRproviders/staff_documents.dart';

class PartTimerDocumentsScreen extends StatefulWidget {
  final int staffId;
  const PartTimerDocumentsScreen({super.key, required this.staffId});

  @override
  State<PartTimerDocumentsScreen> createState() =>
      _PartTimerDocumentsScreenState();
}

class _PartTimerDocumentsScreenState extends State<PartTimerDocumentsScreen> {
  static const Color _primary    = Color(0xFFF97316);
  static const Color _bg         = Color(0xFFFFF7ED);
  static const Color _cardBorder = Color(0xFFFFE4C4);

  static const Map<String, IconData> _typeIcons = {
    'Resume':          Icons.description_rounded,
    'Identity Card':   Icons.badge_rounded,
    'Bank Statement':  Icons.account_balance_rounded,
  };

  bool _isLoading = true;
  final Set<String> _uploadingTypes = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    await Provider.of<StaffDocuments>(context, listen: false)
        .fetchSubmissions(widget.staffId);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickAndUpload(String documentType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    setState(() => _uploadingTypes.add(documentType));

    final docsProv = Provider.of<StaffDocuments>(context, listen: false);
    final res = await docsProv.uploadDocument(
      staffId: widget.staffId,
      documentType: documentType,
      file: result.files.first,
    );

    if (!mounted) return;
    setState(() => _uploadingTypes.remove(documentType));

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['success'] == true
          ? '✅ $documentType uploaded'
          : '❌ ${res['message'] ?? 'Upload failed'}'),
      backgroundColor: res['success'] == true ? Colors.teal : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        title: const Text(
          'My Documents',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              color: _primary,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline_rounded,
                            color: Colors.blue.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Upload a PDF for each document. Uploading a new file replaces the previous one.',
                            style: TextStyle(
                                fontSize: 12.5, color: Colors.blue.shade800),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    ...StaffDocuments.documentTypes
                        .map((type) => _buildDocumentCard(type)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDocumentCard(String documentType) {
    final docsProv = Provider.of<StaffDocuments>(context);
    final doc = docsProv.forType(documentType);
    final isUploading = _uploadingTypes.contains(documentType);
    final uploaded = doc != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (uploaded ? Colors.teal : _primary).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_typeIcons[documentType] ?? Icons.insert_drive_file,
                  color: uploaded ? Colors.teal : _primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(documentType,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (uploaded ? Colors.teal : Colors.grey)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      uploaded
                          ? 'Uploaded${doc.submittedAt != null ? ' — ${DateFormat('dd MMM yyyy').format(doc.submittedAt!)}' : ''}'
                          : 'Not uploaded',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: uploaded ? Colors.teal : Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            if (uploaded) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewDocument(doc),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View'),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed:
                    isUploading ? null : () => _pickAndUpload(documentType),
                icon: isUploading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(uploaded ? Icons.refresh_rounded : Icons.upload_rounded,
                        size: 16),
                label: Text(uploaded ? 'Replace' : 'Upload PDF'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
