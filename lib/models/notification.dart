import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? referenceId;
  final String? referenceType;
  final String? recipientId;
  final String? recipientType;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.referenceId,
    this.referenceType,
    this.recipientId,
    this.recipientType,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String docId) {
    return AppNotification(
      id: docId,
      type: map['type'] ?? 'info',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      referenceId: map['referenceId'],
      referenceType: map['referenceType'],
      recipientId: map['recipientId'],
      recipientType: map['recipientType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'body': body,
      'createdAt': createdAt,
      'isRead': isRead,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'recipientId': recipientId,
      'recipientType': recipientType,
    };
  }
}
