import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  StreamSubscription? _notifSub;

  NotificationProvider() {
    _init();
  }

  bool get isLoading => _isLoading;
  List<AppNotification> get allNotifications => _notifications;

  void _init() {
    _auth.authStateChanges().listen((user) {
      _notifSub?.cancel();
      if (user != null) {
        _notifSub = _db
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((snapshot) {
          _notifications = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            // Assuming timeAgo is derived or stored as a string for now
            return AppNotification.fromMap(data);
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

  int get unreadCount => _notifications.where((n) => !n.read).length;

  Future<void> markRead(String id) async {
    await _db.collection('notifications').doc(id).update({'read': true});
  }

  Future<void> markAllRead() async {
    final batch = _db.batch();
    for (final n in _notifications) {
      if (!n.read) {
        batch.update(_db.collection('notifications').doc(n.id), {'read': true});
      }
    }
    await batch.commit();
  }
}
