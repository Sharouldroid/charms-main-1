import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charms/utils/responsive_helper.dart';
import 'dart:convert';

class NotificationPage extends StatefulWidget {
  final int userId;
  final String hostname;
  const NotificationPage({super.key, required this.userId, required this.hostname});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List notifications = [];
  bool isLoading = true;
  Set<int> selectedIds = {};
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse(
          "https://devcms.com.my/charmsAPI/api/notifications/${widget.userId}"));
      if (res.statusCode == 200) {
        setState(() => notifications = json.decode(res.body));
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> markAsRead(int id) async {
    try {
      final response = await http.get(Uri.parse(
          "https://devcms.com.my/charmsAPI/api/notifications-item/$id/read"));
      if (response.statusCode == 200) {
        setState(() {
          final index = notifications.indexWhere((n) => n['id'] == id);
          if (index != -1) notifications[index]['status'] = 'read';
        });
      }
    } catch (e) {
      debugPrint("Read Error: $e");
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      final response = await http.delete(Uri.parse(
          "https://devcms.com.my/charmsAPI/api/notifications-item/$id"));
      if (response.statusCode == 200) {
        setState(() => notifications.removeWhere((item) => item['id'] == id));
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  Future<void> deleteAll() async {
    try {
      final response = await http.delete(Uri.parse(
          "https://devcms.com.my/charmsAPI/api/notifications/${widget.userId}/delete-all"));
      if (response.statusCode == 200) {
        setState(() {
          notifications.clear();
          isSelectionMode = false;
        });
      }
    } catch (e) {
      debugPrint("Delete All Error: $e");
    }
  }

  // Approval & Rejection endpoints
  Future<void> approveUser(String pendingUserId) async {
    final url = '${widget.hostname}users/approve/$pendingUserId';
    final response = await http.put(Uri.parse(url));
    if (response.statusCode != 200) throw Exception('Approval failed');
  }

  Future<void> rejectUser(String pendingUserId) async {
    final url = '${widget.hostname}users/reject/$pendingUserId';
    final response = await http.put(Uri.parse(url));
    if (response.statusCode != 200) throw Exception('Rejection failed');
  }

  // Helper: returns human‑readable message for display
  String getDisplayMessage(Map notif) {
    dynamic msg = notif['message'];
    if (msg == null) return '';

    // If it's a string, try to parse as JSON
    if (msg is String) {
      try {
        final parsed = json.decode(msg);
        if (parsed is Map && parsed.containsKey('text')) {
          return parsed['text'];
        }
        return msg; // not a JSON object with 'text', return original
      } catch (e) {
        return msg; // not JSON, return raw string
      }
    }
    // If it's already a map, try to get 'text'
    else if (msg is Map && msg.containsKey('text')) {
      return msg['text'];
    }
    return msg.toString();
  }

  void showNotificationDetails(Map notif) async {
    bool isApproval = notif['title'] == 'New User Pending Approval';
    String? pendingUserId;
    String displayMessage = getDisplayMessage(notif);

    if (isApproval) {
      try {
        dynamic messageData = notif['message'];
        if (messageData is String) {
          messageData = json.decode(messageData);
        }
        pendingUserId = messageData['user_id']?.toString();
      } catch (e) {
        isApproval = false;
      }
    }

    if (isApproval && pendingUserId != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(notif['title']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayMessage),
              const SizedBox(height: 12),
              const Text(
                'Please review this registration and either approve or reject it.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await approveUser(pendingUserId!);
                  await markAsRead(notif['id']);
                  await fetchNotifications();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User approved successfully. They can now log in.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Approval failed: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text("Approve", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await rejectUser(pendingUserId!);
                  await markAsRead(notif['id']);
                  await fetchNotifications();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User rejected. The user will be notified.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Rejection failed: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text("Reject", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (notif['status'] != 'read') markAsRead(notif['id']);
              },
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(notif['title']),
          content: Text(displayMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (notif['status'] != 'read') markAsRead(notif['id']);
              },
              child: const Text("Close"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final padding = ResponsiveHelper.getResponsivePadding(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF05179),
        title: Text(isSelectionMode ? "${selectedIds.length} Selected" : "Notifications"),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: Icon(isSelectionMode ? Icons.close : Icons.select_all),
              onPressed: () {
                setState(() {
                  isSelectionMode = !isSelectionMode;
                  selectedIds.clear();
                });
              },
            ),
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () => deleteAll(),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: ListView.builder(
                  padding: padding,
                  itemCount: notifications.length,
                  itemBuilder: (ctx, i) {
                    final notif = notifications[i];
                    final bool isRead = notif['status'] == 'read';
                    final displayMsg = getDisplayMessage(notif); // <-- always use helper
                    return Dismissible(
                      key: Key(notif['id'].toString()),
                      onDismissed: (_) => deleteNotification(notif['id']),
                      background: Container(color: Colors.red, child: const Icon(Icons.delete, color: Colors.white)),
                      child: ListTile(
                        onTap: () => showNotificationDetails(notif),
                        leading: CircleAvatar(
                          radius: isTablet ? 24 : 20,
                          backgroundColor: isRead ? Colors.grey : Colors.blue,
                          child: Icon(isRead ? Icons.done : Icons.notifications, size: isTablet ? 24 : 20),
                        ),
                        title: Text(
                          notif['title'], 
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: isTablet ? 18 : 16,
                          ),
                        ),
                        subtitle: Text(
                          displayMsg, // <-- human-readable text
                          maxLines: 1,
                          style: TextStyle(fontSize: isTablet ? 14 : 12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}