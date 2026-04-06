import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:charms/utils/responsive_helper.dart';

class EventsettingScreen extends StatefulWidget {
  const EventsettingScreen({
    super.key,
    required this.hostname,
    required this.settingtype,
  });

  final String hostname;
  final int settingtype;

  @override
  State<EventsettingScreen> createState() => _EventsettingScreenState();
}

class _EventsettingScreenState extends State<EventsettingScreen> {
  String? _currentPosterUrl;
  bool _posterLoading = false;
  bool _posterError = false;
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  // Call this in initState
  @override
  void initState() {
    super.initState();
    _loadCurrentPoster();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
      });
    } else {
      _showSnackBar('No file selected.');
    }
  }

  Future<void> _submitForm() async {
    if (_selectedFile == null) {
      _showSnackBar('Please select a file to upload.');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${widget.hostname}fileupload/uploadposter'),
      );

      // Get file extension from original filename
      final extension = _selectedFile!.name.split('.').last;
      final filename = 'poster.$extension';

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _selectedFile!.path!,
          filename: filename,
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        _showSnackBar('Poster uploaded successfully!');
        Navigator.of(context).pop();
      } else {
        _showSnackBar('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _loadCurrentPoster() async {
    setState(() {
      _posterLoading = true;
      _posterError = false;
    });

    try {
      final response = await http
          .get(Uri.parse('${widget.hostname}fileupload/getcurrentposter'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _currentPosterUrl = data['url'];
          _posterLoading = false;
        });
      } else {
        setState(() {
          _posterLoading = false;
          _posterError = true;
        });
      }
    } catch (e) {
      setState(() {
        _posterLoading = false;
        _posterError = true;
      });
      debugPrint('Error loading poster: $e');
    }
  }

  // Updated dialog builder
  void _showImageUploadDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text(
              'Upload Event Poster',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Current Poster',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  if (_posterLoading)
                    const CircularProgressIndicator()
                  else if (_posterError)
                    const Text(
                      'No poster found',
                      style: TextStyle(color: Colors.grey),
                    )
                  else if (_currentPosterUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _currentPosterUrl!,
                        height: 150,
                        fit: BoxFit.cover,
                        cacheWidth: 300, // Optimizes memory usage
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error, color: Colors.red);
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_selectedFile != null) ...[
                    Chip(
                      label: Text(
                        _selectedFile!.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () => setState(() => _selectedFile = null),
                    ),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Select Image'),
                    onPressed: _pickFile,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon:
                        _isUploading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                            : const Icon(Icons.cloud_upload),
                    label: Text(
                      _isUploading ? 'Uploading...' : 'Upload Poster',
                    ),
                    onPressed: _isUploading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Event Settings'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: padding,
            child: Column(
              children: [
            Card(
              child: ListTile(
                title: const Text(
                  'Event Poster',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Upload or change the event poster image'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: _showImageUploadDialog,
                ),
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}
