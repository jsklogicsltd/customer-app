import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/quote.dart';

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
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      pendingQuotes = snapshot.docs.map((doc) {
        return QuoteModel.fromFirestore(doc.data(), doc.id);
      }).toList();
      _isLoading = false;
      notifyListeners();
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

  Future<void> acceptQuote(String quoteId, String orderId, num finalPrice) async {
    try {
      final batch = _db.batch();

      // 1. Update quote status to accepted
      batch.update(_db.collection('quotes').doc(quoteId), {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update order status and confirmed price
      batch.update(_db.collection('orders').doc(orderId), {
        'status': 'in-production',
        'confirmedPrice': finalPrice,
        'customerConfirmedAt': FieldValue.serverTimestamp(),
        'progressPercent': 10, // Initial progress
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
      
      // Locally remove from pendingQuotes for immediate UI feedback
      pendingQuotes.removeWhere((q) => q.id == quoteId);
      notifyListeners();
      
      debugPrint('Quote $quoteId accepted via batch');
    } catch (e) {
      debugPrint('Error accepting quote: $e');
      rethrow;
    }
  }

  Future<void> declineQuote(String quoteId, String orderId) async {
    try {
      final batch = _db.batch();

      // 1. Update quote status to declined
      batch.update(_db.collection('quotes').doc(quoteId), {
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update order status to quote-declined
      batch.update(_db.collection('orders').doc(orderId), {
        'status': 'quote-declined',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelReason': 'Customer declined vendor quote',
      });

      await batch.commit();

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
