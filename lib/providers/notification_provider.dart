import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';
import '../service/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  bool _permissionGranted = false;
  int _unreadCount = 0;
  List<NotificationModel> _messages = [];
  bool _isLoading = false;

  bool get permissionGranted => _permissionGranted;
  int get unreadCount => _unreadCount;
  List<NotificationModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  void setPermissionGranted(bool granted) {
    _permissionGranted = granted;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      _messages = await NotificationService.fetchNotifications();
      _unreadCount = _messages.where((m) => m.isUnread).length;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addMessage(RemoteMessage message) {
    // Convert incoming FCM to local model so UI updates immediately
    final model = NotificationModel(
      id: message.messageId ?? DateTime.now().toString(),
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      data: message.data,
      isUnread: true,
      createdAt: message.sentTime ?? DateTime.now(),
    );
    _messages.insert(0, model);
    _unreadCount++;
    notifyListeners();
    
    // Optionally refetch from server to get correct IDs, but optimistic update is fine.
    // fetchNotifications();
  }

  Future<void> markAsRead(String id) async {
    try {
      final index = _messages.indexWhere((m) => m.id == id);
      if (index != -1 && _messages[index].isUnread) {
        _messages[index] = NotificationModel(
          id: _messages[index].id,
          title: _messages[index].title,
          body: _messages[index].body,
          data: _messages[index].data,
          isUnread: false,
          createdAt: _messages[index].createdAt,
        );
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        notifyListeners();
      }
      await NotificationService.markNotificationRead(id);
    } catch (e) {
      debugPrint('Error marking read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      for (var i = 0; i < _messages.length; i++) {
        if (_messages[i].isUnread) {
          _messages[i] = NotificationModel(
            id: _messages[i].id,
            title: _messages[i].title,
            body: _messages[i].body,
            data: _messages[i].data,
            isUnread: false,
            createdAt: _messages[i].createdAt,
          );
        }
      }
      _unreadCount = 0;
      notifyListeners();
      await NotificationService.markAllNotificationsRead();
    } catch (e) {
      debugPrint('Error marking all read: $e');
    }
  }

  void clearUnread() {
    markAllAsRead();
  }
}
