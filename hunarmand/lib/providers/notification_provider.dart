import 'package:flutter/material.dart';
import '../data/mock/mock_notifications.dart';
import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  late List<AppNotification> _notifications;

  NotificationProvider() {
    _notifications = List.from(mockNotificationsData);
  }

  List<AppNotification> get allNotifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.read).length;

  void markRead(String id) {
    final notif = _notifications.firstWhere((n) => n.id == id, orElse: () => _notifications.first);
    notif.read = true;
    notifyListeners();
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.read = true;
    }
    notifyListeners();
  }
}
