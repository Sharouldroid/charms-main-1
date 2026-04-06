import 'package:flutter/material.dart';
import 'docs_upload.dart';

class SubmissionStatusPage extends StatefulWidget {
  final int userId;

  const SubmissionStatusPage({
    super.key,
    required this.userId,
  });

  @override
  _SubmissionStatusPageState createState() => _SubmissionStatusPageState();
}

class _SubmissionStatusPageState extends State<SubmissionStatusPage> {
  Map<String, dynamic>? _submission;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSubmission();
  }

  Future<void> _loadSubmission() async {
    setState(() {
      _isLoading = true;
    });

    // Mock data for testing - replace with actual API call later
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    setState(() {
      // Mock submission data
      _submission = {
        'id': 1,
        'file_name': 'Internship_Application_${widget.userId}.pdf',
        'upload_date': '2025-09-08T10:30:00',
        'status':
            'resubmit', // Change this to test different statuses: pending, approved, rejected, resubmit
        'admin_comments':
            'Please update your docs with more accurate data and ensure all documents are properly signed.',
        'file_size': 2048576, // 2MB
        'submission_count': 2,
      };
      _isLoading = false;
    });

    // TODO: Replace with actual API call
    /*
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/submissions/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _submission = data.isNotEmpty ? data.first : null;
        });
      } else {
        _showErrorMessage('Failed to load submission');
      }
    } catch (e) {
      _showErrorMessage('Error loading submission: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
    */
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resubmitDocument() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocsUpload(
          userId: widget.userId,
          scheduleId: 1, // You might want to get this from the submission data
        ),
      ),
    ).then((_) {
      // Reload submission when returning from upload page
      _loadSubmission();
    });
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

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Your submission is being reviewed by the admin.';
      case 'approved':
        return 'Congratulations! Your submission has been approved.';
      case 'rejected':
        return 'Your submission has been rejected. Please check the comments below.';
      case 'resubmit':
        return 'Please resubmit your documents with the requested changes.';
      default:
        return 'Unknown status.';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Status'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _submission == null
              ? _buildNoSubmissionView()
              : _buildSubmissionView(),
    );
  }

  Widget _buildNoSubmissionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Submission Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You haven\'t submitted any documents yet.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _resubmitDocument,
              icon: const Icon(Icons.upload_file),
              label: const Text('Submit Documents'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionView() {
    final submission = _submission!;
    final status = submission['status'] as String;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header Card
          Card(
            elevation: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    statusIcon,
                    size: 64,
                    color: statusColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusDescription(status),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Submission Details Card
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Submission Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('File Name', submission['file_name']),
                  _buildDetailRow(
                      'Upload Date', _formatDate(submission['upload_date'])),
                  _buildDetailRow(
                      'File Size', _formatFileSize(submission['file_size'])),
                  _buildDetailRow(
                      'Submission Count', '${submission['submission_count']}'),
                ],
              ),
            ),
          ),

          // Admin Comments (if any)
          if (submission['admin_comments'] != null &&
              submission['admin_comments'].isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.comment, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Admin Comments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Text(
                        submission['admin_comments'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Action Buttons
          if (status.toLowerCase() == 'resubmit') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resubmitDocument,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Resubmit Documents'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else if (status.toLowerCase() == 'rejected') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resubmitDocument,
                icon: const Icon(Icons.upload_file, size: 20),
                label: const Text('Submit New Documents'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Refresh Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loadSubmission,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Status'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
