import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Sends a notification to Firestore.
  /// If recipientType is 'admin', it broadcasts to ALL resolved admin UIDs.
  static Future<void> sendNotification({
    required String recipientId,
    required String recipientType,
    required String title,
    required String body,
    required String type,
    String? referenceId,
    String? referenceType,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      List<String> recipientIds = [recipientId];

      // Dynamically resolve all admin UIDs when sending to admin
      if (recipientType == 'admin') {
        final resolvedIds = await _resolveAdminUids();
        if (resolvedIds.isNotEmpty) {
          recipientIds = resolvedIds;
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      final batch = _db.batch();

      for (String id in recipientIds) {
        final docRef = _db.collection('notifications').doc();
        batch.set(docRef, {
          'recipientId': id,
          'recipientType': recipientType,
          'senderId': user?.uid ?? '',
          'senderType': 'customer',
          'title': title,
          'body': body,
          'type': type,
          'referenceId': referenceId,
          'referenceType': referenceType,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          if (extraData != null) ...extraData,
        });
      }

      await batch.commit();
      debugPrint(
        '✅ Notification(s) sent: $type to $recipientType '
        '(${recipientIds.length} recipient(s): ${recipientIds.join(", ")})',
      );
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  /// Resolves ALL active admin UIDs from the adminUsers collection.
  /// Falls back to the users collection (role == 'admin') if needed.
  /// As a last resort, uses the known primary admin UID.
  static Future<List<String>> _resolveAdminUids() async {
    final Set<String> adminUids = {};
    try {
      // PRIMARY: adminUsers collection — document ID IS the UID
      // Also check the 'uid' field inside the document for reliability
      final adminUsersSnap = await _db.collection('adminUsers').get();
      for (var doc in adminUsersSnap.docs) {
        final data = doc.data();
        final isActive = data['isActive'] as bool? ?? true;
        if (!isActive) continue; // skip disabled admins

        // Prefer the 'uid' field stored in the document
        final uidFromField = data['uid'] as String?;
        if (uidFromField != null && uidFromField.isNotEmpty) {
          adminUids.add(uidFromField);
        }
        // Also add doc.id as a safety net (doc ID == UID in adminUsers)
        adminUids.add(doc.id);
      }

      // SECONDARY: users collection with role == 'admin'
      if (adminUids.isEmpty) {
        final usersSnap = await _db
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .get();
        for (var doc in usersSnap.docs) {
          adminUids.add(doc.id);
        }
      }
    } catch (e) {
      debugPrint('Error resolving admin UIDs: $e');
    }

    // FALLBACK: known primary admin UID (note: correct '0' not 'O')
    if (adminUids.isEmpty) {
      adminUids.add('5LA0B4Z2tVch0tTGtmBw5t1Fa9a2');
    }

    debugPrint('🔍 Resolved admin UIDs: ${adminUids.toList()}');
    return adminUids.toList();
  }
}
