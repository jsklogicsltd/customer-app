import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/review.dart';

class ReviewProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Map<String, List<ReviewModel>> _productReviews = {};
  final Map<String, StreamSubscription?> _subs = {};

  List<ReviewModel> getReviews(String productId) {
    if (!_subs.containsKey(productId)) {
      _initReviewListener(productId);
    }
    return _productReviews[productId] ?? [];
  }

  void _initReviewListener(String productId) {
    _subs[productId] = _db
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .snapshots()
        .listen((snapshot) {
      _productReviews[productId] = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ReviewModel.fromMap(data);
      }).toList();
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error fetching reviews for $productId: $e');
    });
  }

  @override
  void dispose() {
    for (var sub in _subs.values) {
      sub?.cancel();
    }
    super.dispose();
  }

  Future<void> addReview(ReviewModel review) async {
    await _db.collection('reviews').add({
      'productId': review.orderId, // Using orderId as productId reference if needed
      'vendorId': review.vendorId,
      'customerName': review.customerName,
      'customerAvatar': review.customerAvatar,
      'rating': review.rating,
      'comment': review.comment,
      'timestamp': FieldValue.serverTimestamp(),
      'date': DateTime.now().toIso8601String(),
      'weeksAgo': 'Just now',
    });
  }
}
