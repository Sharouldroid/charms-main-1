// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:internship/config/api_config.dart';
// import 'docs_upload.dart';

// class ResubmitPage extends StatefulWidget {
//   final int userId;

//   const ResubmitPage({
//     Key? key,
//     required this.userId,
//   }) : super(key: key);

//   @override
//   _ResubmitPageState createState() => _ResubmitPageState();
// }

// class _ResubmitPageState extends State<ResubmitPage> {
//   Map<String, dynamic>? _submission;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadSubmission();
//   }

//   Future<void> _loadSubmission() async {
//     setState(() {
//       _isLoading = true;
//     });

//     // Mock data for testing - replace with actual API call later
//     await Future.delayed(Duration(seconds: 1)); // Simulate network delay
    
//     setState(() {
//       // Mock submission data
//       _submission = {
//         'id': 1,
//         'file_name': 'Internship_Application_${widget.userId}.pdf',
//         'upload_date': '2025-09-08T10:30:00',
//         'status': 'resubmit', // Change this to test different statuses: pending, approved, rejected, resubmit
//         'admin_comments': 'Please update your CV with more recent work experience and ensure all documents are properly signed.',
//         'file_size': 2048576, // 2MB
//         'submission_count': 2,
//       };
//       _isLoading = false;
//     });

//     // TODO: Replace with actual API call
//     /*
//     try {
//       final response = await http.get(
//         Uri.parse('${ApiConfig.baseUrl}/api/submissions/${widget.userId}'),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body) as List;
//         setState(() {
//           _submission = data.isNotEmpty ? data.first : null;
//         });
//       } else {
//         _showErrorMessage('Failed to load submission');
//       }
//     } catch (e) {
//       _showErrorMessage('Error loading submission: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//     */
//   }
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   void _showErrorMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   void _navigateToUpload() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => DocsUpload(userId: widget.userId),
//       ),
//     ).then((_) {
//       // Reload submissions when returning from upload page
//       _loadSubmissions();
//     });
//   }

//   List<Map<String, dynamic>> get filteredSubmissions {
//     if (_selectedFilter == 'all') {
//       return _submissions;
//     }
//     return _submissions
//         .where((sub) => sub['status'] == _selectedFilter)
//         .toList();
//   }

//   Widget _buildStatusIcon(String status) {
//     switch (status) {
//       case 'pending':
//         return Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.orange.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(50),
//           ),
//           child: Icon(Icons.hourglass_empty, color: Colors.orange, size: 24),
//         );
//       case 'approved':
//         return Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.green.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(50),
//           ),
//           child: Icon(Icons.check_circle, color: Colors.green, size: 24),
//         );
//       case 'rejected':
//         return Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.red.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(50),
//           ),
//           child: Icon(Icons.cancel, color: Colors.red, size: 24),
//         );
//       case 'resubmit':
//         return Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.blue.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(50),
//           ),
//           child: Icon(Icons.refresh, color: Colors.blue, size: 24),
//         );
//       default:
//         return Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.grey.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(50),
//           ),
//           child: Icon(Icons.help, color: Colors.grey, size: 24),
//         );
//     }
//   }

//   Widget _buildSubmissionCard(Map<String, dynamic> submission) {
//     String status = submission['status'];
//     DateTime uploadDate = DateTime.parse(submission['upload_date']);

//     return Card(
//       margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header with status icon and info
//             Row(
//               children: [
//                 _buildStatusIcon(status),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         _getStatusTitle(status),
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                           color: _getStatusColor(status),
//                         ),
//                       ),
//                       Text(
//                         'Uploaded on ${uploadDate.day}/${uploadDate.month}/${uploadDate.year}',
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),

//             SizedBox(height: 16),

//             // File information
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey[200]!),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.insert_drive_file, color: Colors.blue),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           submission['file_name'],
//                           style: TextStyle(
//                             fontWeight: FontWeight.w500,
//                             fontSize: 14,
//                           ),
//                         ),
//                         if (submission['file_size'] != null)
//                           Text(
//                             '${(submission['file_size'] / 1024 / 1024).toStringAsFixed(2)} MB',
//                             style: TextStyle(
//                               color: Colors.grey[600],
//                               fontSize: 12,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // Status description
//             SizedBox(height: 12),
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: _getStatusColor(status).withOpacity(0.05),
//                 borderRadius: BorderRadius.circular(8),
//                 border:
//                     Border.all(color: _getStatusColor(status).withOpacity(0.3)),
//               ),
//               child: Text(
//                 _getStatusDescription(status),
//                 style: TextStyle(
//                   color: _getStatusColor(status),
//                   fontSize: 13,
//                 ),
//               ),
//             ),

//             // Admin comments if available
//             if (submission['admin_comments'] != null &&
//                 submission['admin_comments'].isNotEmpty) ...[
//               SizedBox(height: 12),
//               Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.blue[50],
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.blue[200]!),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(Icons.comment, size: 16, color: Colors.blue[700]),
//                         SizedBox(width: 4),
//                         Text(
//                           'Admin Feedback:',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 12,
//                             color: Colors.blue[700],
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 6),
//                     Text(
//                       submission['admin_comments'],
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Colors.blue[800],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],

//             // Action button for resubmit status
//             if (status == 'resubmit') ...[
//               SizedBox(height: 16),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   onPressed: _navigateToUpload,
//                   icon: Icon(Icons.upload_file),
//                   label: Text('Submit New Document'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     foregroundColor: Colors.white,
//                     padding: EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   String _getStatusTitle(String status) {
//     switch (status) {
//       case 'pending':
//         return 'Under Review';
//       case 'approved':
//         return 'Approved';
//       case 'rejected':
//         return 'Rejected';
//       case 'resubmit':
//         return 'Resubmission Required';
//       default:
//         return 'Unknown Status';
//     }
//   }

//   String _getStatusDescription(String status) {
//     switch (status) {
//       case 'pending':
//         return 'Your document is currently being reviewed by the admin. You will be notified once the review is complete.';
//       case 'approved':
//         return 'Congratulations! Your document has been approved. No further action is required.';
//       case 'rejected':
//         return 'Your document has been rejected. Please check the admin feedback and submit a new document.';
//       case 'resubmit':
//         return 'Please review the admin feedback and submit a corrected version of your document.';
//       default:
//         return 'Status information not available.';
//     }
//   }

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'pending':
//         return Colors.orange;
//       case 'approved':
//         return Colors.green;
//       case 'rejected':
//         return Colors.red;
//       case 'resubmit':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }

//   Widget _buildFilterChip(String value, String label, int count) {
//     return Padding(
//       padding: EdgeInsets.only(right: 8),
//       child: FilterChip(
//         label: Text('$label ($count)'),
//         selected: _selectedFilter == value,
//         onSelected: (selected) {
//           setState(() {
//             _selectedFilter = value;
//           });
//         },
//         selectedColor: Colors.blueAccent.withOpacity(0.2),
//         checkmarkColor: Colors.blueAccent,
//       ),
//     );
//   }

//   int _getStatusCount(String status) {
//     if (status == 'all') return _submissions.length;
//     return _submissions.where((sub) => sub['status'] == status).length;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Submission Status'),
//         backgroundColor: Colors.blueAccent,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: _loadSubmissions,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Summary card
//           Container(
//             margin: EdgeInsets.all(16),
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.blueAccent, Colors.blue[700]!],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.blue.withOpacity(0.3),
//                   blurRadius: 8,
//                   offset: Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.assignment, color: Colors.white, size: 32),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Document Submissions',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         'Track your submission status and resubmit if needed',
//                         style: TextStyle(
//                           color: Colors.white.withOpacity(0.9),
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Filter chips
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 16),
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: [
//                   _buildFilterChip('all', 'All', _getStatusCount('all')),
//                   _buildFilterChip(
//                       'pending', 'Pending', _getStatusCount('pending')),
//                   _buildFilterChip(
//                       'approved', 'Approved', _getStatusCount('approved')),
//                   _buildFilterChip(
//                       'rejected', 'Rejected', _getStatusCount('rejected')),
//                   _buildFilterChip(
//                       'resubmit', 'Resubmit', _getStatusCount('resubmit')),
//                 ],
//               ),
//             ),
//           ),

//           SizedBox(height: 16),

//           // Submissions list
//           Expanded(
//             child: _isLoading
//                 ? Center(child: CircularProgressIndicator())
//                 : filteredSubmissions.isEmpty
//                     ? Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               _selectedFilter == 'all'
//                                   ? Icons.inbox
//                                   : Icons.filter_list,
//                               size: 64,
//                               color: Colors.grey[400],
//                             ),
//                             SizedBox(height: 16),
//                             Text(
//                               _selectedFilter == 'all'
//                                   ? 'No submissions yet'
//                                   : 'No ${_selectedFilter} submissions',
//                               style: TextStyle(
//                                 color: Colors.grey[600],
//                                 fontSize: 16,
//                               ),
//                             ),
//                             if (_selectedFilter == 'all') ...[
//                               SizedBox(height: 16),
//                               ElevatedButton.icon(
//                                 onPressed: _navigateToUpload,
//                                 icon: Icon(Icons.upload_file),
//                                 label: Text('Upload First Document'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blueAccent,
//                                   foregroundColor: Colors.white,
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       )
//                     : ListView.builder(
//                         itemCount: filteredSubmissions.length,
//                         itemBuilder: (context, index) {
//                           return _buildSubmissionCard(
//                               filteredSubmissions[index]);
//                         },
//                       ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _navigateToUpload,
//         icon: Icon(Icons.add),
//         label: Text('New Upload'),
//         backgroundColor: Colors.blueAccent,
//         foregroundColor: Colors.white,
//       ),
//     );
//   }
// }
