import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:charms/main.dart';
import 'package:charms/internshipproviders/internship_notification_provider.dart';
import 'package:charms/internshipscreens/admin_submissions.dart';
import 'package:charms/internshipscreens/intern_list_assesstment.dart';
import 'package:charms/internshipscreens/interview_session_admin_screen.dart';

class InternshipNotificationScreen extends StatefulWidget {
  final int userId;
  final bool isAdmin;

  const InternshipNotificationScreen({
    super.key,
    required this.userId,
    required this.isAdmin,
  });

  @override
  State<InternshipNotificationScreen> createState() =>
      _InternshipNotificationScreenState();
}

class _InternshipNotificationScreenState
    extends State<InternshipNotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _debugError;

  final Color bgColor     = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() { _isLoading = true; _debugError = null; });
    try {
      final url = widget.isAdmin
          ? '${AppConfig.hostname}/api/internship/notifications/admin'
          : '${AppConfig.hostname}/api/internship/notifications/user/${widget.userId}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> list = [];
        if (decoded is Map && decoded['data'] != null) {
          final inner = decoded['data'];
          list = inner is List ? inner : [inner];
        } else if (decoded is List) {
          list = decoded;
        }
        setState(() {
          _notifications = list.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } else {
        setState(() => _debugError = 'API returned ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _debugError = 'Exception: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await http.put(
        Uri.parse('${AppConfig.hostname}/api/internship/notifications/$notificationId/read'),
        headers: {'Content-Type': 'application/json'},
      );
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) _notifications[index]['is_read'] = 1;
      });
      if (mounted) context.read<InternshipNotificationProvider>().decrementCount();
    } catch (e) {
      debugPrint('❌ Error marking as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final url = widget.isAdmin
          ? '${AppConfig.hostname}/api/internship/notifications/admin/read-all'
          : '${AppConfig.hostname}/api/internship/notifications/user/${widget.userId}/read-all';
      await http.put(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      setState(() { for (final n in _notifications) n['is_read'] = 1; });
      if (mounted) {
        context.read<InternshipNotificationProvider>().clearCount();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.delete_forever, color: Colors.red, size: 22),
          SizedBox(width: 8),
          Text('Clear All', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: const Text(
          'This will permanently delete all notifications. This action cannot be undone.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      // Delete each notification individually
      for (final n in _notifications) {
        await http.delete(
          Uri.parse('${AppConfig.hostname}/api/internship/notifications/${n['id']}'),
          headers: {'Content-Type': 'application/json'},
        );
      }
      setState(() => _notifications.clear());
      if (mounted) {
        context.read<InternshipNotificationProvider>().clearCount();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('All notifications cleared'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to clear: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final id   = notification['id'] as int;
    final type = notification['type'] ?? '';

    // Mark as read first
    if (notification['is_read'] == 0) _markAsRead(id);

    if (!widget.isAdmin) return; // Intern taps do nothing extra

    // Admin navigation based on type
    if (['new_document', 'document_approved', 'document_rejected',
         'document_resubmit', 'document_status_updated'].contains(type)) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => AdminSubmissionsPage(adminId: widget.userId),
      ));
    } else if (type == 'new_registration') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => const InternListPage(),
      ));
    } else if (type == 'interview_booked') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => const InterviewSessionAdminScreen(),
      ));
    }
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.done_all, color: Colors.green),
              ),
              title: const Text('Mark All as Read',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Keep notifications, mark as read'),
              onTap: () {
                Navigator.pop(ctx);
                _markAllAsRead();
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever, color: Colors.red),
              ),
              title: const Text('Clear All Notifications',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              subtitle: const Text('Permanently delete all notifications'),
              onTap: () {
                Navigator.pop(ctx);
                _clearAllNotifications();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  int get _unreadCount => _notifications.where((n) => n['is_read'] == 0).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('NOTIFICATIONS',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadNotifications,
          ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: _showOptionsMenu,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _debugError != null
              ? _buildErrorState()
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text('Failed to load notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(_debugError!,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade800)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_rounded, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No notifications yet',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('You\'re all caught up!',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    final unread = _notifications.where((n) => n['is_read'] == 0).toList();
    final read   = _notifications.where((n) => n['is_read'] == 1).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Unread count banner
        if (_unreadCount > 0) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryBlue.withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(Icons.circle_notifications_rounded, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                '$_unreadCount unread notification${_unreadCount > 1 ? 's' : ''}',
                style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ]),
          ),
        ],

        if (unread.isNotEmpty) ...[
          _buildSectionHeader('New', Icons.fiber_new_rounded, Colors.redAccent),
          ...unread.map((n) => _buildNotificationCard(n)),
          const SizedBox(height: 8),
        ],

        if (read.isNotEmpty) ...[
          _buildSectionHeader('Earlier', Icons.history_rounded, Colors.grey),
          ...read.map((n) => _buildNotificationCard(n)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 4),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B))),
      ]),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final type   = notification['type'] ?? '';
    final isRead = notification['is_read'] == 1;

    // Determine icon, color, title, subtitle per type
    IconData icon;
    Color    iconColor;
    String   title;
    String   subtitle;
    bool     isTappable = false;

    switch (type) {
      case 'new_document':
        icon = Icons.upload_file_rounded; iconColor = Colors.orange;
        title = notification['title'] ?? 'New Document Submitted';
        subtitle = notification['message'] ?? 'A new document has been uploaded';
        isTappable = widget.isAdmin;
        break;
      case 'document_approved':
        icon = Icons.check_circle_rounded; iconColor = Colors.green;
        title = notification['title'] ?? 'Document Approved ✅';
        subtitle = notification['message'] ?? 'Your document has been approved';
        isTappable = widget.isAdmin;
        break;
      case 'document_rejected':
        icon = Icons.cancel_rounded; iconColor = Colors.redAccent;
        title = notification['title'] ?? 'Document Rejected ❌';
        subtitle = notification['message'] ?? 'Your document was rejected';
        isTappable = widget.isAdmin;
        break;
      case 'document_resubmit':
        icon = Icons.refresh_rounded; iconColor = Colors.blue;
        title = notification['title'] ?? 'Resubmission Requested 🔄';
        subtitle = notification['message'] ?? 'Please resubmit your document';
        isTappable = widget.isAdmin;
        break;
      case 'document_status_updated':
        icon = Icons.update_rounded; iconColor = Colors.teal;
        title = notification['title'] ?? 'Submission Status Updated';
        subtitle = notification['message'] ?? 'A submission status has changed';
        isTappable = widget.isAdmin;
        break;
      case 'registration_confirmed':
        icon = Icons.how_to_reg_rounded; iconColor = Colors.blueAccent;
        title = notification['title'] ?? 'Registration Confirmed ✅';
        subtitle = notification['message'] ?? 'Your internship registration is confirmed';
        break;
      case 'new_registration':
        icon = Icons.person_add_rounded; iconColor = Colors.purple;
        title = notification['title'] ?? 'New Intern Registered';
        subtitle = notification['message'] ?? 'A new intern has registered';
        isTappable = widget.isAdmin;
        break;
      case 'interview_booked_confirmation':
        icon = Icons.event_available_rounded; iconColor = Colors.blueAccent;
        title = notification['title'] ?? 'Interview Session Booked ✅';
        subtitle = notification['message'] ?? 'Your interview session has been scheduled';
        break;
      case 'interview_link_ready':
        icon = Icons.videocam_rounded; iconColor = Colors.teal;
        title = notification['title'] ?? 'Interview Link Ready 🔗';
        subtitle = notification['message'] ?? 'Your interview meeting link is now available';
        break;
      case 'interview_booked':
        icon = Icons.event_note_rounded; iconColor = Colors.purple;
        title = notification['title'] ?? 'Interview Slot Booked';
        subtitle = notification['message'] ?? 'An intern has booked an interview slot';
        isTappable = widget.isAdmin;
        break;
      default:
        icon = Icons.notifications_rounded; iconColor = Colors.blueAccent;
        title = notification['title'] ?? 'Notification';
        subtitle = notification['message'] ?? '';
    }

    // Time ago
    String timeAgo = '';
    if (notification['created_at'] != null) {
      try {
        final dt   = DateTime.parse(notification['created_at']);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60)    timeAgo = '${diff.inMinutes}m ago';
        else if (diff.inHours < 24) timeAgo = '${diff.inHours}h ago';
        else                        timeAgo = '${diff.inDays}d ago';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isRead ? null : Border.all(color: iconColor.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(isRead ? 0.03 : 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(title,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              color: const Color(0xFF1E293B))),
                    ),
                    if (!isRead)
                      Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                              color: iconColor, shape: BoxShape.circle)),
                  ]),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500)),
                  if (timeAgo.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.access_time, size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(timeAgo,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                      if (isTappable) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Tap to view',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: iconColor,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ]),
                  ],
                ]),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isTappable ? iconColor : Colors.grey.shade300),
            ]),
          ),
        ),
      ),
    );
  }
}