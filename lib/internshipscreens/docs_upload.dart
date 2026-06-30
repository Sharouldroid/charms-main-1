import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/main.dart';
import 'package:http_parser/http_parser.dart';

class DocsUpload extends StatefulWidget {
  final int userId;
  final int? scheduleId;

  const DocsUpload({
    super.key,
    required this.userId,
    this.scheduleId,
  });

  @override
  _DocsUploadState createState() => _DocsUploadState();
}

class _DocsUploadState extends State<DocsUpload> {
  PlatformFile? _selectedFile;
  final TextEditingController _linkController = TextEditingController();
  bool _isUploading = false;
  String? _uploadMessage;
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoadingSubmissions = false;

  @override
  void initState() {
    super.initState();
    _loadUserSubmissions();
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _loadUserSubmissions() async {
    setState(() {
      _isLoadingSubmissions = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.hostname}/api/internship/documents/submissions/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _submissions = data.cast<Map<String, dynamic>>();
        });
      } else {
        print('Failed to load submissions: ${response.statusCode}');
        setState(() {
          _submissions = [];
        });
      }
    } catch (e) {
      print('Error loading submissions: $e');
      setState(() {
        _submissions = [];
      });
    } finally {
      setState(() {
        _isLoadingSubmissions = false;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      withData: kIsWeb,
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
        _uploadMessage = null;
      });
    }
  }

  Future<void> _uploadFile() async {
    final link = _linkController.text.trim();

    if (_selectedFile == null && link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file or enter a link')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadMessage = null;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.hostname}/api/internship/documents/upload'),
      );

      request.headers['Accept'] = 'application/json';

      // ✅ Web vs Mobile file handling (only if a file was picked)
      if (_selectedFile != null) {
        if (kIsWeb) {
          final bytes = _selectedFile!.bytes;
          if (bytes == null) {
            throw Exception('Failed to read file bytes');
          }

          final filename = _selectedFile!.name;
          final ext = filename.split('.').last.toLowerCase();

          MediaType contentType;
          if (ext == 'pdf') {
            contentType = MediaType('application', 'pdf');
          } else if (ext == 'doc' || ext == 'docx') {
            contentType = MediaType('application', 'msword');
          } else if (ext == 'jpg' || ext == 'jpeg') {
            contentType = MediaType('image', 'jpeg');
          } else if (ext == 'png') {
            contentType = MediaType('image', 'png');
          } else {
            contentType = MediaType('application', 'octet-stream');
          }

          request.files.add(
            http.MultipartFile.fromBytes(
              'document',
              bytes,
              filename: filename,
              contentType: contentType,
            ),
          );
        } else {
          final path = _selectedFile!.path;
          if (path == null) {
            throw Exception('File path is null');
          }

          request.files.add(
            await http.MultipartFile.fromPath(
              'document',
              path,
            ),
          );
        }
      }

      // Add form fields
      request.fields['userId'] = widget.userId.toString();
      if (widget.scheduleId != null) {
        request.fields['scheduleId'] = widget.scheduleId.toString();
      }
      if (link.isNotEmpty) {
        request.fields['documentLink'] = link;
      }

      print('📤 Uploading — file: ${_selectedFile?.name ?? "none"}, link: ${link.isEmpty ? "none" : link}');
      print('📤 URL: ${AppConfig.hostname}/api/internship/documents/upload');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _uploadMessage = 'Submitted successfully! Awaiting admin review.';
          _selectedFile = null;
          _linkController.clear();
        });

        _loadUserSubmissions();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _uploadMessage = 'Failed to submit: ${errorData['error'] ?? 'Unknown error'}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Submit failed: ${errorData['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Upload error: $e');
      setState(() {
        _uploadMessage = 'Error: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Upload error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // ✅ Only pending / rejected / resubmit documents may be deleted.
  // Approved documents are locked and cannot be removed by the intern.
  bool _canDelete(String status) {
    final s = status.toLowerCase();
    return s == 'pending' || s == 'rejected' || s == 'resubmit';
  }

  Future<void> _confirmAndDelete(dynamic submissionId, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Submission'),
        content: Text('Are you sure you want to delete "$label"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Normalize id to int regardless of whether the API returned int or string
    final id = submissionId is int
        ? submissionId
        : int.tryParse(submissionId.toString());

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Invalid submission id'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.hostname}/api/internship/documents/submissions/$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Submission deleted'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUserSubmissions();
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${errorData['error'] ?? 'Delete failed'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Delete error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'resubmit':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'resubmit':
        return Icons.refresh;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Upload'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoadingSubmissions
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upload Section
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cloud_upload,
                            size: 48,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Upload Your Documents',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Accepted: PDF, DOC, DOCX, JPG, JPEG, PNG — or paste a link below',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          // File Selection Display
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _selectedFile != null
                                ? Row(
                                    children: [
                                      const Icon(Icons.insert_drive_file,
                                          color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _selectedFile!.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _selectedFile = null;
                                          });
                                        },
                                      ),
                                    ],
                                  )
                                : const Column(
                                    children: [
                                      Icon(Icons.file_present,
                                          size: 32, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('No file selected'),
                                    ],
                                  ),
                          ),

                          const SizedBox(height: 16),

                          // ✅ Link input field
                          TextField(
                            controller: _linkController,
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              labelText: 'Or paste a link (optional)',
                              hintText: 'https://drive.google.com/...',
                              prefixIcon: const Icon(Icons.link),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickFile,
                                  icon: const Icon(Icons.folder_open),
                                  label: const Text('Select File'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isUploading
                                      ? null
                                      : _uploadFile,
                                  icon: _isUploading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.upload),
                                  label: Text(_isUploading ? 'Uploading...' : 'Submit'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (_uploadMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _uploadMessage!,
                              style: TextStyle(
                                color: _uploadMessage!.contains('success')
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Submissions List
                  const Text(
                    'Your Submissions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _submissions.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No submissions yet',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _submissions.length,
                          itemBuilder: (context, index) {
                            final submission = _submissions[index];
                            final status = submission['status'] ?? 'pending';
                            final adminComment = submission['admin_comments'];
                            final documentLink = submission['document_link'];
                            final label = submission['file_name'] ??
                                submission['details'] ??
                                'Document';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            label,
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        Chip(
                                          label: Text(
                                            status.toUpperCase(),
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                          backgroundColor: _getStatusColor(status).withOpacity(0.2),
                                        ),
                                        // ✅ Delete button — only shown for
                                        // pending / rejected / resubmit submissions
                                        if (_canDelete(status)) ...[
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline,
                                                color: Colors.red, size: 20),
                                            tooltip: 'Delete submission',
                                            onPressed: () => _confirmAndDelete(
                                              submission['id'],
                                              label,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      'Submitted: ${submission['submitted_at'] ?? 'Unknown'}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),

                                    // ✅ Show link if present
                                    if (documentLink != null && documentLink.toString().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.link, size: 14, color: Colors.indigo),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              documentLink.toString(),
                                              style: const TextStyle(fontSize: 12, color: Colors.indigo),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    // Show admin comment if rejected or resubmit
                                    if (adminComment != null && adminComment.toString().isNotEmpty &&
                                        (status == 'rejected' || status == 'resubmit')) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: status == 'rejected'
                                              ? Colors.red.shade50
                                              : Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: status == 'rejected'
                                                ? Colors.red.shade200
                                                : Colors.blue.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.comment_rounded,
                                              size: 16,
                                              color: status == 'rejected' ? Colors.red : Colors.blue,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Admin Comment:',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: status == 'rejected'
                                                          ? Colors.red.shade700
                                                          : Colors.blue.shade700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    adminComment.toString(),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: status == 'rejected'
                                                          ? Colors.red.shade800
                                                          : Colors.blue.shade800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        backgroundColor: Colors.blueAccent,
        tooltip: 'Back to Dashboard',
        child: const Icon(Icons.home, color: Colors.white),
      ),
    );
  }
}