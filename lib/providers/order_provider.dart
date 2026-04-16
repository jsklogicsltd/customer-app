import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/split_order.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<OrderModel> pendingOrders = [];
  List<OrderModel> activeOrders = [];
  List<OrderModel> completedOrders = [];
  List<OrderModel> cancelledOrders = [];
  List<OrderModel> normalQuotesList = [];
  List<SplitOrderModel> splitOrderQuotesList = [];
  List<SplitOrderModel> activeSplitOrdersList = [];
  
  bool isAccepting = false;
  bool _isLoading = false;
  int _ordersTabIndex = 0;
  final int activeTabIndex = 3;
  final int cancelledTabIndex = 5;

  StreamSubscription? _ordersSubscription;
  StreamSubscription? _splitOrdersQuoteSub;
  StreamSubscription? _splitOrdersActiveSub;

  OrderProvider() {
    _init();
  }

  bool get isLoading => _isLoading || isAccepting;
  int get ordersTabIndex => _ordersTabIndex;
  set ordersTabIndex(int value) {
    _ordersTabIndex = value;
    notifyListeners();
  }
  List<OrderModel> get allOrders => [...normalQuotesList, ...pendingOrders, ...activeOrders, ...completedOrders, ...cancelledOrders];

  void _init() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        debugPrint('>>> OrderProvider: Auth state USER detected uid=${user.uid}');
        listenToCustomerOrders(user.uid);  // pass uid explicitly
        loadSplitOrderQuotes(user.uid);
      } else {
        debugPrint('>>> OrderProvider: Auth state NULL - clearing all lists');
        cancelOrdersListener();
        pendingOrders = [];
        activeOrders = [];
        completedOrders = [];
        cancelledOrders = [];
        normalQuotesList = [];
        splitOrderQuotesList = [];
        activeSplitOrdersList = [];
        notifyListeners();
      }
    });
  }

  void listenToCustomerOrders([String? explicitUid]) {
    final uid = explicitUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      debugPrint('>>> OrderProvider: listenToCustomerOrders() called with EMPTY uid — aborting!');
      return;
    }

    debugPrint('>>> OrderProvider: Starting Firestore listener for orders where customerId == $uid');

    _ordersSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _ordersSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
          debugPrint('>>> OrderProvider: Snapshot received — ${snapshot.docs.length} raw docs from Firestore');
          try {
            // Parse each doc individually so one bad document doesn't crash the whole list
            final allOrdersList = <OrderModel>[];
            for (final doc in snapshot.docs) {
              try {
                allOrdersList.add(OrderModel.fromMap(doc.data(), doc.id));
              } catch (docErr) {
                debugPrint('>>> OrderProvider: Skipping malformed doc ${doc.id}: $docErr');
              }
            }

            // Client-side sort: ensure newest Activity (updatedAt) is always at the top
            allOrdersList.sort((a, b) {
              final aTime = (a.updatedAt as Timestamp?)?.toDate() 
                  ?? (a.createdAt as Timestamp?)?.toDate() 
                  ?? DateTime(2000);
              final bTime = (b.updatedAt as Timestamp?)?.toDate() 
                  ?? (b.createdAt as Timestamp?)?.toDate() 
                  ?? DateTime(2000);
              return bTime.compareTo(aTime); // Descending
            });

            // Pending tab
            pendingOrders = allOrdersList.where((o) => [
              'pending-approval',
              'approved',
              'vendor-notified',
              'vendor-confirmed',
              'quote-submitted',
              'quote-sent-to-customer',
              'quote-sent',
              'awaiting-quote',
              'rfq-sent',
            ].contains(o.status)).toList();

            // Quotes tab — orders where admin has sent final quote to customer
            normalQuotesList = allOrdersList.where((o) =>
              ['quote-sent-to-customer', 'quote-sent', 'split-confirmed'].contains(o.status)
            ).toList();

            // Active tab — status is normalised (lowercase, underscores→dashes) before matching
            activeOrders = allOrdersList.where((o) => [
              'customer-confirmed',
              'active',
              'confirmed',
              'accepted',
              'processing',
              'in-production',
              'ready-to-ship',
              'dispatched',
              'shipped',
              'delivered',
              'out-for-delivery',
              'shipped-to-warehouse',
              'picked-up',
              'ready',
              'ready-to-pickup',
              'at-warehouse',
            ].contains(o.status.toLowerCase().replaceAll('_', '-'))).toList();

            // Completed tab
            completedOrders = allOrdersList
                .where((o) => o.status == 'completed')
                .toList();

            // Cancelled tab
            cancelledOrders = allOrdersList.where((o) => [
              'cancelled',
              'quote-declined',
            ].contains(o.status)).toList();
            debugPrint('>>> DIAGNOSTIC: Found ${allOrdersList.length} total orders for user.');
            debugPrint('>>> DIAGNOSTIC: Unique statuses found: ${allOrdersList.map((o) => o.status).toSet()}');
            
            // Log orders that wouldn't show in any tab
            final accountedStatuses = {
              'pending-approval', 'approved', 'vendor-notified', 'vendor-confirmed', 'quote-submitted', 'quote-sent-to-customer', 'quote-sent',
              'awaiting-quote', 'rfq-sent', 'split-confirmed', 'customer-confirmed', 'active', 'confirmed', 'in-production', 'ready-to-ship', 
              'dispatched', 'shipped', 'delivered', 'out-for-delivery', 'shipped-to-warehouse', 'picked-up', 'ready', 'at-warehouse',
              'completed', 'cancelled', 'quote-declined'
            };
            final unknown = allOrdersList.where((o) => !accountedStatuses.contains(o.status)).toList();
            if (unknown.isNotEmpty) {
              debugPrint('>>> DIAGNOSTIC: found ${unknown.length} orders with UNKNOWN status: ${unknown.map((o) => "${o.id}:${o.status}").toList()}');
            }

          } catch (e) {
            debugPrint('>>> OrderProvider PARSING ERROR: $e');
          } finally {
            _isLoading = false;
            notifyListeners();
          }

        }, onError: (e) {
          debugPrint('>>> OrderProvider: FIRESTORE ERROR — $e');
          if (e.toString().contains('permission-denied') || e.toString().contains('PERMISSION_DENIED')) {
            debugPrint('>>> OrderProvider: PERMISSION DENIED — check Firestore Security Rules for orders collection!');
          }
          _isLoading = false;
          notifyListeners();
        });
  }

  void loadSplitOrderQuotes(String customerId) {
    _splitOrdersQuoteSub?.cancel();
    _splitOrdersQuoteSub = FirebaseFirestore.instance
        .collection('splitOrders')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .listen((snapshot) {
      try {
        splitOrderQuotesList = snapshot.docs
            .map((doc) => SplitOrderModel.fromFirestore(doc))
            .where((s) => s.status == 'quote-sent')
            .toList();
        notifyListeners();
      } catch (e) {
        debugPrint('>>> SplitQuote Provider Error: $e');
      }
    });

    _splitOrdersActiveSub?.cancel();
    _splitOrdersActiveSub = FirebaseFirestore.instance
        .collection('splitOrders')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .listen((snapshot) {
      try {
        activeSplitOrdersList = snapshot.docs
            .map((doc) => SplitOrderModel.fromFirestore(doc))
            .where((s) => [
              'customer-confirmed',
              'active',
              'confirmed',
              'accepted',
              'processing',
              'in-production',
              'ready-to-ship',
              'dispatched',
              'shipped',
              'delivered',
            ].contains(s.status.toLowerCase().replaceAll('_', '-')))
            .toList();
        debugPrint('>>> DIAGNOSTIC: Found ${activeSplitOrdersList.length} active split orders.');
        notifyListeners();
      } catch (e) {
        debugPrint('>>> ActiveSplit Provider Error: $e');
      }
    });
  }

  // Call this on logout to cancel listener
  void cancelOrdersListener() {
    _ordersSubscription?.cancel();
    _splitOrdersQuoteSub?.cancel();
    _splitOrdersActiveSub?.cancel();
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
      'updatedAt':        FieldValue.serverTimestamp(),
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
      'updatedAt': FieldValue.serverTimestamp(),
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
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<OrderPartModel>> watchOrderParts(String orderId) {
    return _db
        .collection('orders')
        .doc(orderId)
        .collection('orderParts')
        .orderBy('partNumber', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderPartModel.fromFirestoreCustomer(doc.data(), doc.id))
            .toList());
  }

  /// Accept a quote that was sent to the customer
  Future<void> acceptNormalQuote(String orderId) async {
    try {
      // Show loading
      isAccepting = true;
      notifyListeners();

      // Update Firestore
      await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({
          'status': 'customer-confirmed',
          'customerConfirmedAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

      debugPrint('>>> normal quote accepted: $orderId');

      // Remove from quotes list immediately for instant UI feedback
      normalQuotesList.removeWhere((o) => o.id == orderId);

      isAccepting = false;

      // Switch to Active tab (index 3)
      ordersTabIndex = activeTabIndex;
      notifyListeners();
    } catch (e) {
      isAccepting = false;
      notifyListeners();
      debugPrint('>>> acceptNormalQuote ERROR: $e');
      rethrow;
    }
  }

  Future<void> declineNormalQuote(String orderId) async {
    try {
      await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({
          'status': 'cancelled',
          'cancellationReason': 'Customer declined quote',
          'cancelledAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

      debugPrint('>>> normal quote declined: $orderId');

      normalQuotesList.removeWhere((o) => o.id == orderId);

      // Switch to Cancelled tab
      ordersTabIndex = cancelledTabIndex;
      notifyListeners();
    } catch (e) {
      debugPrint('>>> declineNormalQuote ERROR: $e');
      rethrow;
    }
  }

  Future<void> acceptSplitQuote(String orderId) async {
    try {
      isAccepting = true;
      notifyListeners();

      // Update parent order status
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'customer-confirmed',
        'customerConfirmedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Update all orderParts to active
      final partsSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .collection('orderParts')
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (final part in partsSnapshot.docs) {
        batch.update(part.reference, {
          'status': 'active',
        });
      }

      await batch.commit();

      // NEW: Also update the summary document in splitOrders collection
      await FirebaseFirestore.instance
          .collection('splitOrders')
          .doc(orderId)
          .update({
        'status': 'active',
        'updatedAt': Timestamp.now(),
      }).catchError((e) => debugPrint('Non-critical: could not update splitOrders doc: $e'));

      // Remove from quotes list locally
      normalQuotesList.removeWhere((o) => o.id == orderId);
      
      isAccepting = false;

      // Switch to Active tab
      ordersTabIndex = activeTabIndex;
      notifyListeners();
    } catch (e) {
      isAccepting = false;
      notifyListeners();
      debugPrint('acceptSplitQuote ERROR: $e');
      rethrow;
    }
  }

  Future<void> declineSplitQuote(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'cancelled',
        'cancellationReason': 'Customer declined split quote',
        'cancelledAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      normalQuotesList.removeWhere((o) => o.id == orderId);

      // Switch to Cancelled tab
      ordersTabIndex = cancelledTabIndex;
      notifyListeners();
    } catch (e) {
      debugPrint('declineSplitQuote ERROR: $e');
      rethrow;
    }
  }
}
