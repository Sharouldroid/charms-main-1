import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:charms/main.dart';
import 'package:charms/internshipproviders/internship_notification_provider.dart';

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
  String? _debugError; // ✅ Show error on screen for debugging

  final Color bgColor = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _debugError = null;
    });

    try {
      final url = widget.isAdmin
          ? '${AppConfig.hostname}/api/internship/notifications/admin'
          : '${AppConfig.hostname}/api/internship/notifications/user/${widget.userId}';

      print('📥 Fetching notifications from: $url');
      print('📥 isAdmin: ${widget.isAdmin} | userId: ${widget.userId}');

      final response = await http.get(Uri.parse(url));

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        print('📥 Decoded type: ${decoded.runtimeType}');

        List<dynamic> list = [];

        if (decoded is Map) {
          print('📥 Keys: ${decoded.keys.toList()}');
          if (decoded['data'] != null) {
            final inner = decoded['data'];
            print('📥 data type: ${inner.runtimeType}');
            if (inner is List) {
              list = inner;
            } else if (inner is Map) {
              list = [inner];
            }
          } else {
            // Maybe response is flat map with notifications at root
            print('📥 No data key found — keys: ${decoded.keys}');
            setState(() => _debugError = 'Response has no "data" key. Keys: ${decoded.keys.toList()}');
          }
        } else if (decoded is List) {
          list = decoded;
        }

        print('📥 Total notifications parsed: ${list.length}');

        setState(() {
          _notifications = list.map((e) => Map<String, dynamic>.from(e)).toList();
        });

      } else {
        print('❌ Non-200 status: ${response.statusCode}');
        setState(() => _debugError = 'API returned ${response.statusCode}: ${response.body}');
      }
    } catch (e, stack) {
      print('❌ Exception: $e');
      print('❌ Stack: $stack');
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
      print('❌ Error marking as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final url = widget.isAdmin
          ? '${AppConfig.hostname}/api/internship/notifications/admin/read-all'
          : '${AppConfig.hostname}/api/internship/notifications/user/${widget.userId}/read-all';

      await http.put(Uri.parse(url), headers: {'Content-Type': 'application/json'});

      setState(() {
        for (final n in _notifications) n['is_read'] = 1;
      });

      if (mounted) {
        context.read<InternshipNotificationProvider>().clearCount();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Read All', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadNotifications,
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

  // ✅ Show error details on screen to help debug
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
              child: Text(
                _debugError!,
                style: TextStyle(fontSize: 12, color: Colors.red.shade800),
              ),
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
          Icon(Icons.notifications_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No notifications yet',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          // ✅ Show debug info
          Text(
            'URL: ${widget.isAdmin ? "admin" : "user/${widget.userId}"}',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
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
              Text('$_unreadCount unread notification${_unreadCount > 1 ? 's' : ''}',
                  style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
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
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ]),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final type   = notification['type'] ?? '';
    final isRead = notification['is_read'] == 1;
    final id     = notification['id'] as int;

    IconData icon;
    Color    iconColor;
    String   title;
    String   subtitle;

    switch (type) {
      case 'document_approved':
        icon = Icons.check_circle_rounded; iconColor = Colors.green;
        title = 'Document Approved ✅';
        subtitle = notification['message'] ?? 'Your document has been approved';
        break;
      case 'document_rejected':
        icon = Icons.cancel_rounded; iconColor = Colors.redAccent;
        title = notification['title'] ?? 'Document Rejected ❌';
        subtitle = notification['message'] ?? 'Your document was rejected. Please resubmit';
        break;
      case 'registration_confirmed':
        icon = Icons.how_to_reg_rounded; iconColor = Colors.blueAccent;
        title = 'Registration Confirmed ✅';
        subtitle = notification['message'] ?? 'Your internship registration is confirmed';
        break;
      case 'new_document':
        icon = Icons.upload_file_rounded; iconColor = Colors.orange;
        title = notification['title'] ?? 'New Document Submitted';
        subtitle = notification['message'] ?? 'A new document has been uploaded';
        break;
      case 'new_registration':
        icon = Icons.person_add_rounded; iconColor = Colors.purple;
        title = 'New Intern Registered';
        subtitle = notification['message'] ?? 'A new intern has registered';
        break;
      case 'document_resubmit':
        icon = Icons.refresh_rounded; iconColor = Colors.blue;
        title = notification['title'] ?? 'Resubmission Requested 🔄';
        subtitle = notification['message'] ?? 'Please resubmit your document';
        break;
      default:
        icon = Icons.notifications_rounded; iconColor = Colors.blueAccent;
        title = notification['title'] ?? 'Notification';
        subtitle = notification['message'] ?? '';
    }

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
          blurRadius: 10, offset: const Offset(0, 4),
        )],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () { if (!isRead) _markAsRead(id); },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(title, style: TextStyle(
                    fontSize: 15,
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ))),
                  if (!isRead) Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                if (timeAgo.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(timeAgo, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ],
              ])),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}