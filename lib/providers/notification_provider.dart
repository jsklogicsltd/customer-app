import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  StreamSubscription? _notifSub;

  NotificationProvider() {
    _init();
  }

  bool get isLoading => _isLoading;
  List<AppNotification> get allNotifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _init() {
    _auth.authStateChanges().listen((user) {
      _notifSub?.cancel();
      if (user != null) {
        _isLoading = true;
        notifyListeners();
        
        _notifSub = _db
            .collection('notifications')
            .where('recipientId', isEqualTo: user.uid)
            .where('recipientType', isEqualTo: 'customer')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen((snapshot) {
          _notifications = snapshot.docs.map((doc) {
            return AppNotification.fromMap(doc.data(), doc.id);
          }).toList();
          
          _isLoading = false;
          notifyListeners();
        }, onError: (e) {
          debugPrint('Error in NotificationProvider listener: $e');
          _isLoading = false;
          notifyListeners();
        });
      } else {
        _notifications = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> markAsRead(String id) async {
    try {
      await _db.collection('notifications').doc(id).update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllRead() async {
    try {
      final batch = _db.batch();
      final unread = _notifications.where((n) => !n.isRead);
      for (final n in unread) {
        batch.update(_db.collection('notifications').doc(n.id), {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}
