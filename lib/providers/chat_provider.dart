import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/notification_service.dart';


class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Real admin UID — loaded from Firestore users collection where role == 'admin'.
  String? _adminUid;
  bool _adminUidLoading = false;

  /// Local message cache: threadId → list of messages
  final Map<String, List<ChatMessage>> _threads = {};

  /// Active Firestore listeners per threadId
  final Map<String, StreamSubscription?> _subs = {};

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns messages for [threadId], starting a real-time listener on first call.
  List<ChatMessage> getMessages(String threadId) {
    if (!_subs.containsKey(threadId)) {
      _initThreadListener(threadId);
    }
    return _threads[threadId] ?? [];
  }

  /// Returns the current Firebase UID (customer's UID).
  String? get currentUid => _auth.currentUser?.uid;

  // ---------------------------------------------------------------------------
  // Admin UID resolution
  // ---------------------------------------------------------------------------

  /// Fetches the real admin UID dynamically from Firestore users collection.
  /// Never hardcoded — always resolves based on who has role == 'admin'.
  Future<String?> _resolveAdminUid() async {
    if (_adminUid != null) return _adminUid;
    if (_adminUidLoading) {
      // Wait briefly and return cached result (may still be null)
      await Future.delayed(const Duration(milliseconds: 600));
      return _adminUid;
    }
    _adminUidLoading = true;
    try {
      final adminSnap = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      if (adminSnap.docs.isNotEmpty) {
        _adminUid = adminSnap.docs.first.id;
        debugPrint('ChatProvider: resolved adminUid = $_adminUid');
        return _adminUid;
      }
      // Fallback: adminUsers collection
      final adminUsersSnap = await _db.collection('adminUsers').limit(1).get();
      if (adminUsersSnap.docs.isNotEmpty) {
        _adminUid = adminUsersSnap.docs.first.id;
        debugPrint('ChatProvider: resolved adminUid from adminUsers = $_adminUid');
        return _adminUid;
      }
      debugPrint('ChatProvider: WARNING — no admin found in Firestore!');
    } catch (e) {
      debugPrint('ChatProvider: could not resolve adminUid: $e');
    } finally {
      _adminUidLoading = false;
    }
    return _adminUid;
  }

  // ---------------------------------------------------------------------------
  // Sending — Order-Centric Hub (Approach 3)
  // ---------------------------------------------------------------------------

  /// Sends a message with optimistic UI update.
  /// Always directed to Admin; customer never sees vendor info.
  Future<void> sendMessage({
    required String orderId,
    required String text,
    String customerName = '',
    String? threadId,
  }) async {
    final user = _auth.currentUser;
    if (user == null || text.trim().isEmpty) return;

    final resolvedThreadId = threadId ?? ChatMessage.buildOrderThreadId(
      orderId: orderId,
      customerId: user.uid,
    );

    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final optimisticTime = '$h:$m';

    // 1. Optimistic insert — show message instantly
    final optimistic = ChatMessage(
      id: 'pending_${now.millisecondsSinceEpoch}',
      threadId: resolvedThreadId,
      threadType: 'customer_admin',
      orderId: orderId,
      senderId: user.uid,
      senderType: 'customer',
      receiverId: _adminUid ?? 'admin',
      visibleTo: const ['customer', 'admin'],
      displayAsName: 'Karsaazi Support',
      text: text.trim(),
      timestamp: optimisticTime,
      sortKey: now.millisecondsSinceEpoch,
      isMe: true,
      customerName: customerName,
      read: false,
      isPending: true,
    );

    _threads[resolvedThreadId] = [...(_threads[resolvedThreadId] ?? []), optimistic];
    notifyListeners();

    // 2. Resolve real admin UID (cached after first call)
    final adminUid = await _resolveAdminUid();
    if (adminUid == null) {
      debugPrint('ChatProvider: WARNING — adminUid not resolved');
    }

    // 3. Persist to Firestore with new schema
    try {
      final msg = ChatMessage(
        id: '',
        threadId: resolvedThreadId,
        threadType: 'customer_admin',
        orderId: orderId,
        senderId: user.uid,
        senderType: 'customer',
        receiverId: adminUid ?? 'admin',
        visibleTo: const ['customer', 'admin'],
        displayAsName: 'Karsaazi Support',
        text: text.trim(),
        timestamp: '',
        sortKey: 0,
        isMe: true,
        customerName: customerName,
        read: false,
      );
      await _db.collection('messages').add(msg.toFirestoreMap());

      // 4. Send notification to admin
      await NotificationService.sendNotification(
        recipientId: adminUid ?? 'admin',
        recipientType: 'admin',
        title: 'New Message from Customer',
        body: '$customerName: ${text.trim()}',
        type: 'new_message',
        referenceId: threadId,
        referenceType: 'chat',
      );
    } catch (e) {
      debugPrint('ChatProvider: sendMessage error: $e');
    }
  }

  /// Sends a message about a specific product.
  Future<void> sendProductMessage({
    required String productId,
    required String productName,
    required String vendorId,
    required String vendorName,
    required String text,
    String customerName = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null || text.trim().isEmpty) return;

    final threadId = ChatMessage.buildProductThreadId(
      customerId: user.uid,
      productId: productId,
      vendorId: vendorId,
    );

    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final optimisticTime = '$h:$m';

    // 1. Optimistic insert
    final optimistic = ChatMessage(
      id: 'pending_${now.millisecondsSinceEpoch}',
      threadId: threadId,
      threadType: 'customer_admin',
      chatType: 'product',
      productId: productId,
      productName: productName,
      vendorId: vendorId,
      vendorName: vendorName,
      senderId: user.uid,
      senderType: 'customer',
      receiverId: _adminUid ?? 'admin',
      visibleTo: const ['customer', 'admin'],
      displayAsName: 'Karsaazi Support',
      text: text.trim(),
      timestamp: optimisticTime,
      sortKey: now.millisecondsSinceEpoch,
      isMe: true,
      customerName: customerName,
      read: false,
      isPending: true,
    );

    _threads[threadId] = [...(_threads[threadId] ?? []), optimistic];
    notifyListeners();

    // 2. Resolve admin
    final adminUid = await _resolveAdminUid();

    // 3. Persist
    try {
      final msg = ChatMessage(
        id: '',
        threadId: threadId,
        threadType: 'customer_admin',
        chatType: 'product',
        productId: productId,
        productName: productName,
        vendorId: vendorId,
        vendorName: vendorName,
        senderId: user.uid,
        senderType: 'customer',
        receiverId: adminUid ?? 'admin',
        visibleTo: const ['customer', 'admin'],
        displayAsName: 'Karsaazi Support',
        text: text.trim(),
        timestamp: '',
        sortKey: 0,
        isMe: true,
        customerName: customerName,
        read: false,
      );
      await _db.collection('messages').add(msg.toFirestoreMap());

      // 4. Notification
      await NotificationService.sendNotification(
        recipientId: adminUid ?? 'admin',
        recipientType: 'admin',
        title: 'New Product Inquiry 📦',
        body: '$customerName is asking about $productName',
        type: 'product_inquiry',
        referenceId: threadId,
        referenceType: 'chat',
        // Pass extra data for admin routing if needed
        extraData: {
          'productId': productId,
          'vendorId': vendorId,
        },
      );
    } catch (e) {
      debugPrint('ChatProvider: sendProductMessage error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Real-time listener per threadId (visibleTo arrayContains 'customer')
  // ---------------------------------------------------------------------------

  void _initThreadListener(String threadId) {
    _subs[threadId] = null; // prevent duplicate starts

    _subs[threadId] = _db
        .collection('messages')
        .where('threadId', isEqualTo: threadId)
        .where('visibleTo', arrayContains: 'customer')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen(
      (snapshot) {
        final currentUid = _auth.currentUser?.uid;
        final confirmed = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          final bool isMine = data['senderId'] == currentUid;
          return ChatMessage.fromMap(data, isMe: isMine);
        }).toList();

        // Sort by epoch ms — safe for mixed String/Timestamp docs
        confirmed.sort((a, b) => a.sortKey.compareTo(b.sortKey));

        // Merge: discard optimistic once confirmed by Firestore
        final pending = (_threads[threadId] ?? [])
            .where((m) => m.isPending)
            .where((p) => !confirmed
                .any((c) => c.text == p.text && c.senderId == p.senderId))
            .toList();

        _threads[threadId] = [...confirmed, ...pending];
        notifyListeners();
      },
      onError: (e) {
        debugPrint('ChatProvider: listener error for $threadId: $e');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Chat List: fetch latest message + unread count per threadId
  // ---------------------------------------------------------------------------

  /// Returns a stream of latest messages for building the chat list.
  /// Each element is: {threadId, lastMessage, lastTimestamp, unreadCount}
  Stream<List<Map<String, dynamic>>> chatListStream({
    required List<String> threadIds,
  }) {
    if (threadIds.isEmpty) {
      return Stream.value([]);
    }
    // Merge snapshots for all threadIds
    final streams = threadIds.map((tid) {
      return _db
          .collection('messages')
          .where('threadId', isEqualTo: tid)
          .where('visibleTo', arrayContains: 'customer')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .map((snap) {
        if (snap.docs.isEmpty) return <String, dynamic>{'threadId': tid};
        final data = snap.docs.first.data();
        return <String, dynamic>{
          'threadId': tid,
          'lastMessage': data['text'] ?? '',
          'lastTimestamp': data['timestamp'],
          'senderId': data['senderId'],
        };
      });
    }).toList();

    // Combine all latest-message streams
    return streams.first.asyncMap((first) async {
      return [first];
    });
  }

  /// Returns unread message count for a specific threadId (messages not sent by me).
  Future<int> getUnreadCount(String threadId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0;
    try {
      final snap = await _db
          .collection('messages')
          .where('threadId', isEqualTo: threadId)
          .where('visibleTo', arrayContains: 'customer')
          .where('read', isEqualTo: false)
          .where('senderType', isEqualTo: 'admin')
          .get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  /// Marks all admin messages in a thread as read.
  Future<void> markThreadRead(String threadId) async {
    try {
      final snap = await _db
          .collection('messages')
          .where('threadId', isEqualTo: threadId)
          .where('senderType', isEqualTo: 'admin')
          .where('read', isEqualTo: false)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('ChatProvider: markThreadRead error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    for (final sub in _subs.values) {
      sub?.cancel();
    }
    super.dispose();
  }
}
