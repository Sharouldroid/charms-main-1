import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/main.dart';

class InternshipNotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;
  bool _isLoading = false;

  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  // ✅ Fetch unread count from backend
  Future<void> fetchUnreadCount(int userId, bool isAdmin) async {
    try {
      _isLoading = true;

      final url = isAdmin
          ? '${AppConfig.hostname}/api/internship/notifications/admin/unread-count'
          : '${AppConfig.hostname}/api/internship/notifications/user/$userId/unread-count';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _unreadCount = data['count'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error fetching unread count: $e');
    } finally {
      _isLoading = false;
    }
  }

  // ✅ Call this after user reads all notifications
  void clearCount() {
    _unreadCount = 0;
    notifyListeners();
  }

  // ✅ Call this to decrement after reading one notification
  void decrementCount() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }
}