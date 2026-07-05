import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/main.dart';
import 'package:url_launcher/url_launcher.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AdminSubmissionsPage extends StatefulWidget {
  final int adminId;

  const AdminSubmissionsPage({
    super.key,
    required this.adminId,
  });

  @override
  _AdminSubmissionsPageState createState() => _AdminSubmissionsPageState();
}

class _AdminSubmissionsPageState extends State<AdminSubmissionsPage> {
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoading = false;
  String _filterStatus = 'all';             // pending/approved/rejected/resubmit
  String _filterInternshipStatus = 'all';   // active/completed

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  // ─── Load Submissions ────────────────────────────────────────────────────────

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.hostname}/api/internship/documents/admin/submissions'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _submissions = data.cast<Map<String, dynamic>>();
        });
      } else {
        _showErrorMessage('Failed to load submissions');
      }
    } catch (e) {
      _showErrorMessage('Error loading submissions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─── Download File ───────────────────────────────────────────────────────────

  Future<void> _downloadFile(int submissionId, String fileName) async {
    try {
      _showLoadingDialog('Downloading file...');

      final response = await http.get(
        Uri.parse('${AppConfig.hostname}/api/internship/documents/download/$submissionId'),
      );

      if (mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        if (kIsWeb) {
          final bytes = response.bodyBytes;
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showErrorMessage('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorMessage('Error downloading file: $e');
    }
  }

  Future<void> _viewFile(int submissionId, String fileName) async {
  try {
    _showLoadingDialog('Opening file...');

    final response = await http.get(
      Uri.parse('${AppConfig.hostname}/api/internship/documents/download/$submissionId'),
    );

    if (mounted) Navigator.of(context).pop();

    if (response.statusCode == 200) {
      if (kIsWeb) {
        final bytes = response.bodyBytes;

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

        final blob = html.Blob([bytes], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);

        html.window.open(url, '_blank');

        Future.delayed(const Duration(seconds: 10), () {
          html.Url.revokeObjectUrl(url);
        });
      }
    } else {
      _showErrorMessage('Failed to open file: ${response.statusCode}');
    }
  } catch (e) {
    if (mounted) Navigator.of(context).pop();
    _showErrorMessage('Error opening file: $e');
  }
}

  // ─── Open Link ───────────────────────────────────────────────────────────────

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showErrorMessage('Invalid link');
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showErrorMessage('Could not open link');
    }
  }

  // ─── Update Status ───────────────────────────────────────────────────────────

  Future<void> _updateSubmissionStatus(
      int submissionId, String status, String comments) async {
    try {
      _showLoadingDialog('Updating status...');

      final response = await http.put(
        Uri.parse(
            '${AppConfig.hostname}/api/internship/documents/submissions/$submissionId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status,
          'adminComments': comments,
        }),
      );

      if (mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSubmissions();
      } else {
        String errorMessage = 'Failed to update status';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['error'] ?? errorData['message'] ?? 'Unknown error';
        } catch (e) {
          if (response.body.contains('<!DOCTYPE') ||
              response.body.contains('<html')) {
            errorMessage =
                'Server error (${response.statusCode}). Please check the API endpoint.';
          } else {
            errorMessage = 'Server error: ${response.body}';
          }
        }
        _showErrorMessage(errorMessage);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorMessage('Error updating status: $e');
    }
  }

  // ─── Delete Submission ───────────────────────────────────────────────────────

  Future<void> _deleteSubmission(int submissionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Submission'),
        content: const Text(
            'Are you sure you want to delete this submission? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      _showLoadingDialog('Deleting...');

      final response = await http.delete(
        Uri.parse(
            '${AppConfig.hostname}/api/internship/documents/submissions/$submissionId'),
      );

      if (mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSubmissions();
      } else {
        _showErrorMessage('Failed to delete submission');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorMessage('Error deleting: $e');
    }
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────────────

  void _showStatusDialog(Map<String, dynamic> submission) {
    String selectedStatus = submission['status'] ?? 'pending';
    TextEditingController commentsController = TextEditingController(
      text: submission['admin_comments'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Submission Status'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student: ${submission['first_name'] ?? 'Unknown'} ${submission['last_name'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('File: ${submission['file_name'] ?? 'Unnamed File'}'),
              if (submission['document_type'] != null &&
                  submission['document_type'].toString().isNotEmpty)
                Text('Document Type: ${submission['document_type']}'),
              const SizedBox(height: 16),
              const Text('Status:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(
                      value: 'approved', child: Text('Approved')),
                  DropdownMenuItem(
                      value: 'rejected', child: Text('Rejected')),
                  DropdownMenuItem(
                      value: 'resubmit', child: Text('Request Resubmit')),
                ],
                onChanged: (value) {
                  selectedStatus = value!;
                },
              ),
              const SizedBox(height: 16),
              const Text('Comments:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: commentsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Add comments (optional)',
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateSubmissionStatus(
                submission['id'],
                selectedStatus,
                commentsController.text,
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(String message) {
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

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ─── Filter ──────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get filteredSubmissions {
    var result = _submissions;

    if (_filterStatus != 'all') {
      result = result.where((sub) => sub['status'] == _filterStatus).toList();
    }

    if (_filterInternshipStatus != 'all') {
      result = result
          .where((sub) => sub['internship_status'] == _filterInternshipStatus)
          .toList();
    }

    return result;
  }

  // ─── Submission Card ─────────────────────────────────────────────────────────

  Widget _buildSubmissionCard(Map<String, dynamic> submission) {
    Color statusColor;
    IconData statusIcon;

    switch (submission['status']) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'resubmit':
        statusColor = Colors.blue;
        statusIcon = Icons.refresh;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    final hasFile = submission['file_name'] != null &&
        submission['file_name'].toString().isNotEmpty;
    final documentLink = submission['document_link'];
    final hasLink = documentLink != null && documentLink.toString().isNotEmpty;
    final documentType = submission['document_type'];
    final hasDocumentType =
        documentType != null && documentType.toString().isNotEmpty;

    // Internship Active/Completed badge (only shown if backend provided it)
    final internshipStatus = submission['internship_status'];
    final hasInternshipStatus =
        internshipStatus != null && internshipStatus.toString().isNotEmpty;
    final isInternshipActive = internshipStatus == 'active';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: student info + status badges ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${submission['first_name'] ?? 'Unknown'} ${submission['last_name'] ?? ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        submission['email'] ?? '-',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (hasDocumentType) ...[
                        const SizedBox(height: 4),
                        Text(
                          documentType.toString(),
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            (submission['status'] ?? 'unknown')
                                .toString()
                                .toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasInternshipStatus) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isInternshipActive
                                  ? Colors.teal
                                  : Colors.grey)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isInternshipActive
                                ? Colors.teal
                                : Colors.grey,
                          ),
                        ),
                        child: Text(
                          isInternshipActive ? 'ACTIVE' : 'COMPLETED',
                          style: TextStyle(
                            color: isInternshipActive
                                ? Colors.teal[700]
                                : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── File info (only if a file exists) ──
            if (hasFile)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            submission['file_name'] ?? 'Unnamed File',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Uploaded: ${submission['upload_date'] != null ? DateTime.parse(submission['upload_date']).toString().split(' ')[0] : 'Unknown'}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ── Link info (only if a link exists) ──
            if (hasLink) ...[
              if (hasFile) const SizedBox(height: 8),
              InkWell(
                onTap: () => _openLink(documentLink.toString()),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          documentLink.toString(),
                          style: const TextStyle(
                            color: Colors.indigo,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.open_in_new, size: 16, color: Colors.indigo),
                    ],
                  ),
                ),
              ),
            ],

            // ── Admin comments ──
            if (submission['admin_comments'] != null &&
                submission['admin_comments'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Comments:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      submission['admin_comments'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Action buttons ──
            Row(
              children: [
                // View (only when a file exists)
                if (hasFile)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewFile(
                        submission['id'],
                        submission['file_name'] ?? 'file',
                      ),
                      icon: const Icon(Icons.visibility, size: 14),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        textStyle: const TextStyle(fontSize: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                if (hasFile) const SizedBox(width: 6),

                // Download (only when a file exists)
                if (hasFile)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadFile(
                        submission['id'],
                        submission['file_name'] ?? 'file',
                      ),
                      icon: const Icon(Icons.download, size: 14),
                      label: const Text('Download'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        textStyle: const TextStyle(fontSize: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                if (hasFile) const SizedBox(width: 6),

                // Review
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showStatusDialog(submission),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Delete
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    onPressed: () => _deleteSubmission(submission['id']),
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    tooltip: 'Delete Submission',
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Filter Chips ────────────────────────────────────────────────────────────

  Widget _buildFilterChip(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _filterStatus == value,
        onSelected: (selected) {
          setState(() => _filterStatus = value);
        },
        selectedColor: Colors.blueAccent.withOpacity(0.2),
        checkmarkColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildInternshipFilterChip(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _filterInternshipStatus == value,
        onSelected: (selected) {
          setState(() => _filterInternshipStatus = value);
        },
        selectedColor: Colors.teal.withOpacity(0.2),
        checkmarkColor: Colors.teal,
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Resume Submissions'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubmissions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Document status filter bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text('Filter: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All'),
                        _buildFilterChip('pending', 'Pending'),
                        _buildFilterChip('approved', 'Approved'),
                        _buildFilterChip('rejected', 'Rejected'),
                        _buildFilterChip('resubmit', 'Resubmit'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Internship status filter bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                const Text('Internship: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildInternshipFilterChip('all', 'All'),
                        _buildInternshipFilterChip('active', 'Active'),
                        _buildInternshipFilterChip('completed', 'Completed'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Submissions list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredSubmissions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _filterStatus == 'all' &&
                                      _filterInternshipStatus == 'all'
                                  ? 'No submissions yet'
                                  : 'No matching submissions',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredSubmissions.length,
                        itemBuilder: (context, index) {
                          return _buildSubmissionCard(
                              filteredSubmissions[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}