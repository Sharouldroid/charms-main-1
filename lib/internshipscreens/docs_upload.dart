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
  PlatformFile? _selectedFile; // ✅ Changed from File to PlatformFile
  bool _isUploading = false;
  String? _uploadMessage;
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoadingSubmissions = false;

  @override
  void initState() {
    super.initState();
    _loadUserSubmissions();
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
      withData: kIsWeb, // ✅ Load bytes on web
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
        _uploadMessage = null;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to upload')),
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

      // ✅ Web vs Mobile file handling (same as HR module)
      if (kIsWeb) {
        // Web: Use bytes
        final bytes = _selectedFile!.bytes;
        if (bytes == null) {
          throw Exception('Failed to read file bytes');
        }

        final filename = _selectedFile!.name;
        final ext = filename.split('.').last.toLowerCase();
        
        // Determine content type
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
        // Mobile: Use path
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

      // Add form fields
      request.fields['userId'] = widget.userId.toString();
      if (widget.scheduleId != null) {
        request.fields['scheduleId'] = widget.scheduleId.toString();
      }

      print('📤 Uploading file: ${_selectedFile!.name}');
      print('📤 URL: ${AppConfig.hostname}/api/internship/documents/upload');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _uploadMessage = 'File uploaded successfully! Awaiting admin review.';
          _selectedFile = null;
        });

        _loadUserSubmissions();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Document uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _uploadMessage = 'Failed to upload: ${errorData['error'] ?? 'Unknown error'}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Upload failed: ${errorData['error']}'),
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
                            'Accepted: PDF, DOC, DOCX, JPG, JPEG, PNG',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
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
                                  onPressed: _isUploading || _selectedFile == null
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
                                  label: Text(_isUploading ? 'Uploading...' : 'Upload'),
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
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: Icon(
                                  _getStatusIcon(status),
                                  color: _getStatusColor(status),
                                ),
                                title: Text(submission['file_name'] ?? submission['details'] ?? 'Document'),
                                subtitle: Text(
                                  'Submitted: ${submission['submitted_at'] ?? 'Unknown'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Chip(
                                  label: Text(
                                    status.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: _getStatusColor(status).withOpacity(0.2),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}