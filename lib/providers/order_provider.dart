import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<OrderModel> pendingOrders = [];
  List<OrderModel> activeOrders = [];
  List<OrderModel> completedOrders = [];
  List<OrderModel> cancelledOrders = [];
  
  bool _isLoading = false;
  StreamSubscription? _ordersSubscription;

  OrderProvider() {
    _init();
  }

  bool get isLoading => _isLoading;
  List<OrderModel> get allOrders => [...pendingOrders, ...activeOrders, ...completedOrders, ...cancelledOrders];

  void _init() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        listenToCustomerOrders();
      } else {
        cancelOrdersListener();
        pendingOrders = [];
        activeOrders = [];
        completedOrders = [];
        cancelledOrders = [];
        notifyListeners();
      }
    });
  }

  void listenToCustomerOrders() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    _ordersSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _ordersSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {

          final allOrdersList = snapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList();

          // Pending tab
          pendingOrders = allOrdersList.where((o) => [
            'pending-approval',
            'vendor-notified',
            'vendor-confirmed',
            'quote-submitted',
            'quote-sent',
          ].contains(o.status)).toList();

          // Active tab
          activeOrders = allOrdersList.where((o) => [
            'in-production',
            'ready-to-ship',
            'dispatched',
            'delivered',
          ].contains(o.status)).toList();

          // Completed tab
          completedOrders = allOrdersList
              .where((o) => o.status == 'completed')
              .toList();

          // Cancelled tab
          cancelledOrders = allOrdersList.where((o) => [
            'cancelled',
            'quote-declined',
          ].contains(o.status)).toList();

          _isLoading = false;
          notifyListeners();

        }, onError: (e) {
          print('Customer orders error: $e');
          _isLoading = false;
          notifyListeners();
        });
  }

  // Call this on logout to cancel listener
  void cancelOrdersListener() {
    _ordersSubscription?.cancel();
  }

  @override
  void dispose() {
    cancelOrdersListener();
    super.dispose();
  }

  OrderModel? getById(String id) {
    try {
      return allOrders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<String> placeOrder({
    required String productId,
    required int quantity,
    required String deliveryAddress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User must be logged in to place an order';

    final productDoc = await _db.collection('products').doc(productId).get();
    if (!productDoc.exists) throw 'Product not found';

    final productData = productDoc.data()!;
    final orderRef = _db.collection('orders').doc();
    
    await orderRef.set({
      'orderId':          orderRef.id,
      'orderNumber':      'ORD-${DateTime.now().year}-${orderRef.id.substring(0,6).toUpperCase()}',
      'customerId':       user.uid,
      'vendorId':         productData['vendorId'] ?? '',
      'productId':        productId,
      'productName':      productData['productName'] ?? '',
      'mainPhotoUrl':     productData['mainPhotoUrl'] ?? '',
      'category':         productData['category'] ?? '',
      'quantity':         quantity,
      'unitPrice':        (productData['unitPrice'] ?? 0).toDouble(),
      'totalAmount':      quantity * (productData['unitPrice'] ?? 0).toDouble(),
      'status':           'pending-approval',
      'deliveryAddress':  deliveryAddress,
      'paymentMethod':    'cash-on-delivery',
      'createdAt':        FieldValue.serverTimestamp(),
      'vendorQuote':      null,
      'commissionAmount': null,
      'customerPrice':    null,
      'reviewed':         false,
    });

    return orderRef.id;
  }

  Future<String> addOrderFromObject(OrderModel order) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User must be logged in';
    
    final data = {
      'orderNumber': order.orderNumber.isEmpty ? order.id : order.orderNumber,
      'customerId': user.uid,
      'productId': order.productId,
      'productName': order.productName,
      'mainPhotoUrl': order.mainPhotoUrl,
      'vendorId': order.vendorId,
      'vendorName': order.vendorName,
      'quantity': order.quantity,
      'unitPrice': order.unitPrice,
      'totalAmount': order.totalAmount,
      'confirmedPrice': order.confirmedPrice,
      'status': order.status,
      'deliveryAddress': order.deliveryAddress,
      'createdAt': FieldValue.serverTimestamp(),
      'timeline': order.timeline.map((t) => {
        'step': t.step,
        'date': t.date,
        'completed': t.completed,
        'current': t.current,
        'note': t.note,
      }).toList(),
      'progressPercent': order.progressPercent,
    };

    final docRef = await _db.collection('orders').add(data);
    return docRef.id;
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    await _db.collection('orders').doc(orderId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelReason': reason,
      'timeline': FieldValue.arrayUnion([
        {
          'step': 'Order Cancelled',
          'date': DateTime.now().toIso8601String(),
          'completed': true,
          'note': reason,
        }
      ]),
    });
  }
}
