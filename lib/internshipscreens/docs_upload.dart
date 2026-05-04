import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

import 'package:charms/main.dart';

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
  File? _file;
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
      // 2. UPDATED URL: Points to Laravel 'internship/documents/submissions/{userId}'
      final response = await http.get(
        Uri.parse('${AppConfig.hostname}/api/internship/submissions/intern/${widget.userId}')
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('API Response: $responseBody'); // Debug log

        final data = jsonDecode(responseBody);
        if (data is List) {
          setState(() {
            _submissions = data.cast<Map<String, dynamic>>();
          });
        } else {
          print('Expected List but got: ${data.runtimeType}');
          setState(() {
            _submissions = [];
          });
        }
      } else {
        print('Failed to load submissions: ${response.statusCode}');
        print('Response body: ${response.body}');
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
    );

    if (result != null) {
      setState(() {
        _file = File(result.files.single.path!);
        _uploadMessage = null;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_file == null) {
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
      // 3. UPDATED URL: Points to Laravel 'internship/documents/upload'
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.hostname}/api/internship/submissions')
      );

      // Add the file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'document',
          _file!.path,
        ),
      );

      // Add userId and scheduleId to the request body
      request.fields['userId'] = widget.userId.toString();
      if (widget.scheduleId != null) {
        request.fields['scheduleId'] = widget.scheduleId.toString();
      }

      // Send the request
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        setState(() {
          _uploadMessage = 'File uploaded successfully! Awaiting admin review.';
          _file = null; // Clear selected file
        });

        // Reload submissions to show the new upload
        _loadUserSubmissions();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorData = jsonDecode(responseBody);
        setState(() {
          _uploadMessage = 'Failed to upload file: ${errorData['message']}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${errorData['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _uploadMessage = 'Error uploading file: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  submission['status'].toString().toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                Text(
                  DateTime.parse(submission['upload_date'])
                      .toString()
                      .split(' ')[0],
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              submission['file_name'],
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (submission['admin_comments'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Comments:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      submission['admin_comments'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Documents'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      'Accepted formats: PDF, DOC, DOCX, JPG, JPEG, PNG',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // File Selection
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _file != null
                          ? Row(
                              children: [
                                const Icon(Icons.insert_drive_file,
                                    color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _file!.path.split('/').last,
                                    style:
                                        const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _file = null;
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
                            onPressed: _isUploading || _file == null
                                ? null
                                : _uploadFile,
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.upload),
                            label:
                                Text(_isUploading ? 'Uploading...' : 'Upload'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_uploadMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _uploadMessage!.contains('successfully')
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _uploadMessage!.contains('successfully')
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Text(
                          _uploadMessage!,
                          style: TextStyle(
                            color: _uploadMessage!.contains('successfully')
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submissions History Section
            const Text(
              'Your Submissions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoadingSubmissions)
              const Center(child: CircularProgressIndicator())
            else if (_submissions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No submissions yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: _submissions
                    .map((submission) => _buildSubmissionCard(submission))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
