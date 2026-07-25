import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationProvider extends ChangeNotifier {
  bool _permissionGranted = false;
  int _unreadCount = 0;
  final List<RemoteMessage> _messages = [];

  bool get permissionGranted => _permissionGranted;
  int get unreadCount => _unreadCount;
  List<RemoteMessage> get messages => List.unmodifiable(_messages);
  void setPermissionGranted(bool granted) {
    _permissionGranted = granted;
    notifyListeners();
  }

  void addMessage(RemoteMessage message) {
    _messages.insert(0, message);
    _unreadCount++;
    notifyListeners();
  }

  void clearUnread() {
    _unreadCount = 0;
    notifyListeners();
  }
}
