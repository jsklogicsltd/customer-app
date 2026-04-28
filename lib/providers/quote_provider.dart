import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../services/notification_service.dart';


class QuoteProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<QuoteModel> pendingQuotes = [];
  bool _isLoading = false;
  StreamSubscription? _quotesSub;

  QuoteProvider() {
    _init();
  }

  bool get isLoading => _isLoading;

  void _init() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        listenToQuotes();
      } else {
        stopListening();
        pendingQuotes = [];
        notifyListeners();
      }
    });
  }

  void listenToQuotes() {
    final user = _auth.currentUser;
    if (user == null) return;

    _quotesSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _quotesSub = _db
        .collection('quotes')
        .where('customerId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      try {
        final allQuotes = snapshot.docs.map((doc) {
          return QuoteModel.fromFirestore(doc.data(), doc.id);
        }).toList();
        
        pendingQuotes = allQuotes.where((q) {
          final s = q.status.toLowerCase().replaceAll('_', '-');
          return s == 'pending' || s == 'sent-to-customer' || s == 'quote-sent';
        }).toList();
      } catch (e) {
        debugPrint('>>> QuoteProvider PARSING ERROR: $e');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('Error in QuoteProvider listener: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  void stopListening() {
    _quotesSub?.cancel();
    _quotesSub = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  Future<void> acceptQuote(String quoteId, String orderId, num finalPrice, {String? customerName}) async {
    try {
      final batch = _db.batch();

      // 1. Update quote status to accepted
      batch.update(_db.collection('quotes').doc(quoteId), {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update order status and confirmed price
      batch.update(_db.collection('orders').doc(orderId), {
        'status': 'in-production',
        'confirmedPrice': finalPrice,
        'customerConfirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'progressPercent': 11,
        'currentStepId': 'order_accepted',
        'currentStepTitle': 'Order Accepted',
        'trackingSteps': [
          {
            'stepId': 'order_accepted',
            'title': 'Order Accepted',
            'description': 'Order has been accepted and confirmed by the customer.',
            'status': 'completed',
            'completedAt': Timestamp.now(),
            'percentage': 11,
          },
          {
            'stepId': 'raw_material',
            'title': 'Raw Material Procured',
            'description': 'Procuring raw materials for production.',
            'status': 'in-progress',
            'completedAt': null,
            'percentage': 22,
          },
          {
            'stepId': 'production_started',
            'title': 'Production Started',
            'status': 'pending',
            'completedAt': null,
            'percentage': 33,
          },
          {
            'stepId': 'production_completed',
            'title': 'Production Completed',
            'status': 'pending',
            'completedAt': null,
            'percentage': 66,
          },
          {
            'stepId': 'ready_for_pickup',
            'title': 'Ready for Pickup',
            'status': 'pending',
            'completedAt': null,
            'percentage': 88,
          },
          {
            'stepId': 'dispatched',
            'title': 'Dispatched',
            'status': 'pending',
            'completedAt': null,
            'percentage': 94,
          }
        ],
        'timeline': FieldValue.arrayUnion([
          {
            'step': 'Quote Accepted',
            'date': DateTime.now().toIso8601String(),
            'completed': true,
            'note': 'Customer accepted the quote and confirmed the order.',
          }
        ]),
      });

      await batch.commit();
      
      // 3. Send notification to admin
      try {
        final adminSnap = await _db
            .collection('adminUsers')
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();
        final adminUID = adminSnap.docs.isNotEmpty
            ? adminSnap.docs.first.id
            : 'h9q4ZLZom1RPv91BJdvllRGpLcS2';

        final currentUserId = _auth.currentUser?.uid ?? 'unknown';

        await _db.collection('notifications').add({
          'recipientId': adminUID,
          'recipientType': 'admin',
          'senderId': currentUserId,
          'senderType': 'customer',
          'title': 'Quote Accepted ✅',
          'body': '${customerName ?? 'A customer'} accepted the quote for order #$orderId',
          'type': 'quote_accepted',
          'referenceId': quoteId,
          'referenceType': 'quote',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error sending quote acceptance notification: $e');
      }

      // Locally remove from pendingQuotes for immediate UI feedback
      pendingQuotes.removeWhere((q) => q.id == quoteId);
      notifyListeners();
      
      debugPrint('Quote $quoteId accepted via batch');

    } catch (e) {
      debugPrint('Error accepting quote: $e');
      rethrow;
    }
  }

  Future<void> declineQuote(String quoteId, String orderId, {String? customerName}) async {
    try {
      final batch = _db.batch();

      // 1. Update quote status to declined
      batch.update(_db.collection('quotes').doc(quoteId), {
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update order status to quote-declined
      batch.update(_db.collection('orders').doc(orderId), {
        'status': 'quote-declined',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelReason': 'Customer declined vendor quote',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // 3. Send notification to admin
      try {
        final adminSnap = await _db
            .collection('adminUsers')
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();
        final adminUID = adminSnap.docs.isNotEmpty
            ? adminSnap.docs.first.id
            : 'h9q4ZLZom1RPv91BJdvllRGpLcS2';

        final currentUserId = _auth.currentUser?.uid ?? 'unknown';

        await _db.collection('notifications').add({
          'recipientId': adminUID,
          'recipientType': 'admin',
          'senderId': currentUserId,
          'senderType': 'customer',
          'title': 'Quote Rejected ❌',
          'body': '${customerName ?? 'A customer'} rejected the quote for order #$orderId',
          'type': 'quote_rejected',
          'referenceId': quoteId,
          'referenceType': 'quote',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error sending quote decline notification: $e');
      }

      // Locally remove from pendingQuotes
      pendingQuotes.removeWhere((q) => q.id == quoteId);
      notifyListeners();
      
      debugPrint('Quote $quoteId declined via batch');

    } catch (e) {
      debugPrint('Error declining quote: $e');
      rethrow;
    }
  }
}
