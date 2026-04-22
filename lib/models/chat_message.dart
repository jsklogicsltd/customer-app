import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;

  // New thread-centric fields
  final String threadId;
  final String threadType;
  final String orderId;
  final String senderId;
  final String senderType;
  final String receiverId;
  final List<String> visibleTo;
  final String displayAsName;
  final String text;
  final Timestamp? firestoreTimestamp;

  // Derived / local fields
  /// Human-readable display time, e.g. "14:35"
  final String timestamp;

  /// Raw epoch milliseconds for sorting (0 = unknown / optimistic)
  final int sortKey;

  final bool isMe;
  final String? customerName;
  final bool read;

  /// Used locally for optimistic display (not stored in Firestore)
  final bool isPending;

  const ChatMessage({
    required this.id,
    this.threadId = '',
    this.threadType = 'customer_admin',
    this.orderId = '',
    required this.senderId,
    this.senderType = 'customer',
    this.receiverId = '',
    this.visibleTo = const ['customer', 'admin'],
    this.displayAsName = 'Karsaazi Support',
    required this.text,
    this.firestoreTimestamp,
    required this.timestamp,
    this.sortKey = 0,
    required this.isMe,
    this.customerName,
    this.read = false,
    this.isPending = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, {bool isMe = false}) {
    String displayTime = '';
    int sortKey = 0;
    Timestamp? firestoreTs;

    final dynamic t = map['timestamp'];
    if (t != null) {
      DateTime? dt;
      if (t is Timestamp) {
        firestoreTs = t;
        dt = t.toDate();
      } else if (t is DateTime) {
        dt = t;
      } else if (t is String) {
        dt = DateTime.tryParse(t);
      } else {
        try {
          firestoreTs = t as Timestamp;
          dt = firestoreTs.toDate();
        } catch (_) {}
      }

      if (dt != null) {
        final local = dt.toLocal();
        final h = local.hour.toString().padLeft(2, '0');
        final m = local.minute.toString().padLeft(2, '0');
        displayTime = '$h:$m';
        sortKey = dt.millisecondsSinceEpoch;
      }
    }

    final visibleTo = map['visibleTo'] != null
        ? List<String>.from(map['visibleTo'] as List)
        : <String>['customer', 'admin'];

    return ChatMessage(
      id: map['id'] ?? '',
      threadId: map['threadId'] ?? '',
      threadType: map['threadType'] ?? 'customer_admin',
      orderId: map['orderId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderType: map['senderType'] ?? 'customer',
      receiverId: map['receiverId'] ?? '',
      visibleTo: visibleTo,
      displayAsName: map['displayAsName'] ?? 'Karsaazi Support',
      text: map['text'] ?? '',
      firestoreTimestamp: firestoreTs,
      timestamp: displayTime,
      sortKey: sortKey,
      isMe: isMe,
      customerName: map['customerName'],
      read: map['read'] ?? false,
    );
  }

  /// Returns structured map ready to persist to Firestore.
  Map<String, dynamic> toFirestoreMap() {
    return {
      'threadId': threadId,
      'threadType': threadType,
      'orderId': orderId,
      'senderId': senderId,
      'senderType': senderType,
      'receiverId': receiverId,
      'visibleTo': visibleTo,
      'displayAsName': displayAsName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'customerName': customerName ?? '',
      'read': false,
    };
  }

  /// Builds the standard threadId for a customer-admin conversation.
  static String buildThreadId({
    required String orderId,
    required String customerId,
  }) =>
      '${orderId}_CUSTOMER_$customerId';
}
