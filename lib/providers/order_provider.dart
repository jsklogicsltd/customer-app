import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/notification_service.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<OrderModel> pendingOrders = [];
  List<OrderModel> activeOrders = [];
  List<OrderModel> completedOrders = [];
  List<OrderModel> cancelledOrders = [];
  List<OrderModel> normalQuotesList = [];
  
  List<OrderModel> get splitOrderQuotesList => normalQuotesList
      .where((o) => o.isSplitOrder == true)
      .toList();

  List<OrderModel> get activeSplitOrdersList => activeOrders
      .where((o) => o.isSplitOrder == true)
      .toList();
  
  bool isAccepting = false;
  bool _isLoading = false;
  int _ordersTabIndex = 0;
  final int activeTabIndex = 3;
  final int cancelledTabIndex = 5;

  StreamSubscription? _ordersSubscription;

  OrderProvider() {
    _init();
  }

  bool get isLoading => _isLoading || isAccepting;
  int get ordersTabIndex => _ordersTabIndex;
  set ordersTabIndex(int value) {
    _ordersTabIndex = value;
    notifyListeners();
  }
  List<OrderModel> get allOrders {
    final Map<String, OrderModel> dedup = {};
    for (var o in [...normalQuotesList, ...pendingOrders, ...activeOrders, ...completedOrders, ...cancelledOrders]) {
      dedup[o.id] = o;
    }
    final sortedList = dedup.values.toList();
    // Sort by date again to be safe
    sortedList.sort((a, b) {
      final aTime = (a.updatedAt as Timestamp?)?.toDate() 
          ?? (a.createdAt as Timestamp?)?.toDate() 
          ?? DateTime(2000);
      final bTime = (b.updatedAt as Timestamp?)?.toDate() 
          ?? (b.createdAt as Timestamp?)?.toDate() 
          ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    return sortedList;
  }

  void _init() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        debugPrint('>>> OrderProvider: Auth state USER detected uid=${user.uid}');
        listenToCustomerOrders(user.uid);  // pass uid explicitly
      } else {
        debugPrint('>>> OrderProvider: Auth state NULL - clearing all lists');
        cancelOrdersListener();
        pendingOrders = [];
        activeOrders = [];
        completedOrders = [];
        cancelledOrders = [];
        normalQuotesList = [];
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

            // Helper for status matching
            bool hasStatus(String status, List<String> targetStatuses) {
              final s = status.toLowerCase().replaceAll('_', '-');
              return targetStatuses.contains(s);
            }

            // Pending tab
            pendingOrders = allOrdersList.where((o) => hasStatus(o.status, [
              'pending-approval',
              'approved',
              'vendor-notified',
              'vendor-confirmed',
              'quote-submitted',
              'awaiting-quote',
              'rfq-sent',
            ])).toList();

            // Quotes tab — orders where admin has sent final quote to customer
            normalQuotesList = allOrdersList.where((o) =>
              hasStatus(o.status, ['quote-sent-to-customer', 'quote-sent', 'split-confirmed'])
            ).toList();

            // Active tab — status is normalised (lowercase, underscores→dashes) before matching
            activeOrders = allOrdersList.where((o) => hasStatus(o.status, [
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
            ])).toList();

            // Completed tab
            completedOrders = allOrdersList
                .where((o) => hasStatus(o.status, ['completed']))
                .toList();

            // Cancelled tab
            cancelledOrders = allOrdersList.where((o) => hasStatus(o.status, [
              'cancelled',
              'quote-declined',
            ])).toList();
            debugPrint('>>> DIAGNOSTIC: Found ${allOrdersList.length} total orders for user.');
            debugPrint('>>> DIAGNOSTIC: Unique statuses found: ${allOrdersList.map((o) => o.status).toSet()}');
            
            // Log orders that wouldn't show in any tab
            final accountedStatuses = {
              'pending-approval', 'approved', 'vendor-notified', 'vendor-confirmed', 'quote-submitted', 'quote-sent-to-customer', 'quote-sent',
              'awaiting-quote', 'rfq-sent', 'split-confirmed', 'customer-confirmed', 'active', 'confirmed', 'in-production', 'ready-to-ship', 
              'dispatched', 'shipped', 'delivered', 'out-for-delivery', 'shipped-to-warehouse', 'picked-up', 'ready', 'at-warehouse',
              'completed', 'cancelled', 'quote-declined'
            };
            final unknown = allOrdersList.where((o) => !accountedStatuses.contains(o.status.toLowerCase().replaceAll('_', '-'))).toList();
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
    String? customerName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User must be logged in to place an order';

    final productDoc = await _db.collection('products').doc(productId).get();
    if (!productDoc.exists) throw 'Product not found';

    final productData = productDoc.data()!;
    final orderRef = _db.collection('orders').doc();
    
    final orderData = {
      'orderId':          orderRef.id,
      'orderNumber':      'ORD-${DateTime.now().year}-${orderRef.id.substring(0,6).toUpperCase()}',
      'customerId':       user.uid,
      'vendorId':         productData['vendorId'] ?? '',
      'productId':        productId,
      'productName':      productData['productName'] ?? productData['name'] ?? '',
      'mainPhotoUrl':     productData['mainPhotoUrl'] ?? productData['mainImageUrl'] ?? productData['imageUrl'] ?? productData['image'] ?? '',
      'vendorName':       productData['vendorName'] ?? '',
      'category':         productData['category'] ?? '',
      'quantity':         quantity,
      'unitPrice':        (productData['unitPrice'] ?? productData['price'] ?? productData['pricePerUnit'] ?? 0).toDouble(),
      'totalAmount':      quantity * (productData['unitPrice'] ?? productData['price'] ?? productData['pricePerUnit'] ?? 0).toDouble(),
      'status':           'pending-approval',
      'deliveryAddress':  deliveryAddress,
      'paymentMethod':    'cash-on-delivery',
      'createdAt':        FieldValue.serverTimestamp(),
      'vendorQuote':      null,
      'commissionAmount': null,
      'customerPrice':    null,
      'reviewed':         false,
      'updatedAt':        FieldValue.serverTimestamp(),
    };

    debugPrint('📦 Current User UID: ${user.uid}');
    debugPrint('📦 Order Data CustomerID: ${orderData['customerId']}');
    debugPrint('📦 Attempting to place order: ${orderRef.id}');
    
    try {
      await orderRef.set(orderData);
      debugPrint('✅ Order document set successfully');
    } catch (e) {
      debugPrint('❌ Firestore set() failed: $e');
      rethrow;
    }

    // Send notification to admin
    try {
      await NotificationService.sendNotification(
        recipientId: 'admin',
        recipientType: 'admin',
        title: 'New Order Received',
        body: '${customerName ?? 'A customer'} placed an order for ${productData['productName'] ?? productData['name'] ?? 'Product'}',
        type: 'new_order',
        referenceId: orderRef.id,
        referenceType: 'order',
      );
    } catch (e) {
      debugPrint('Error sending new order notification: $e');
    }

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

  Future<void> cancelOrder(String orderId, String reason, {String? customerName}) async {
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

    // Send notification to admin
    try {
      final order = getById(orderId);
      await NotificationService.sendNotification(
        recipientId: 'admin',
        recipientType: 'admin',
        title: 'Order Cancelled by Customer',
        body: '${customerName ?? 'A customer'} cancelled order ${order?.orderNumber ?? orderId}',
        type: 'order_update',
        referenceId: orderId,
        referenceType: 'order',
      );
    } catch (e) {
      debugPrint('Error sending cancel order notification: $e');
    }
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
  Future<void> acceptNormalQuote(String orderId, {String? customerName}) async {
    try {
      // Show loading
      isAccepting = true;
      notifyListeners();

      final orderDoc = await _db.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) throw 'Order not found';
      final orderData = orderDoc.data()!;
      
      final finalPrice = (orderData['customerPrice'] ?? orderData['confirmedPrice'] ?? 0.0).toDouble();
      final quoteId = orderData['quoteId'] as String?;

      final batch = _db.batch();

      // 1. Update order status, confirmed price and tracking steps
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

      // 2. Update quote status if it exists
      if (quoteId != null && quoteId.isNotEmpty) {
        batch.update(_db.collection('quotes').doc(quoteId), {
          'status': 'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      debugPrint('>>> normal quote accepted: $orderId');

      // Remove from quotes list immediately for instant UI feedback
      normalQuotesList.removeWhere((o) => o.id == orderId);

      isAccepting = false;

      // Switch to Active tab (index 3)
      ordersTabIndex = activeTabIndex;

      // Send notification to admin
      try {
        await NotificationService.sendNotification(
          recipientId: 'admin',
          recipientType: 'admin',
          title: 'Quote Accepted',
          body: '${customerName ?? 'A customer'} accepted the quote for ${orderData['productName'] ?? 'Order'}',
          type: 'quote_accepted',
          referenceId: orderId,
          referenceType: 'order',
        );

        // Send notification to customer
        if (_auth.currentUser != null) {
          await NotificationService.sendNotification(
            recipientId: _auth.currentUser!.uid,
            recipientType: 'customer',
            title: 'Order Activated',
            body: 'Ap ka order ab active hogyaa hey ab ap es order ki live tracking dek sakty hooo',
            type: 'order_active',
            referenceId: orderId,
            referenceType: 'order',
          );
        }
      } catch (e) {
        debugPrint('Error sending quote acceptance notifications: $e');
      }
    } catch (e) {
      isAccepting = false;
      notifyListeners();
      debugPrint('>>> acceptNormalQuote ERROR: $e');
      rethrow;
    }
  }

  Future<void> declineNormalQuote(String orderId, {String? customerName}) async {
    try {
      final orderDoc = await _db.collection('orders').doc(orderId).get();
      final orderData = orderDoc.data() ?? {};
      final quoteId = orderData['quoteId'] as String?;

      final batch = _db.batch();
      
      batch.update(_db.collection('orders').doc(orderId), {
        'status': 'cancelled',
        'cancellationReason': 'Customer declined quote',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (quoteId != null && quoteId.isNotEmpty) {
        batch.update(_db.collection('quotes').doc(quoteId), {
          'status': 'declined',
          'declinedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      debugPrint('>>> normal quote declined: $orderId');

      normalQuotesList.removeWhere((o) => o.id == orderId);

      // Switch to Cancelled tab
      ordersTabIndex = cancelledTabIndex;

      // Send notification to admin
      try {
        await NotificationService.sendNotification(
          recipientId: 'admin',
          recipientType: 'admin',
          title: 'Quote Declined',
          body: '${customerName ?? 'A customer'} declined the quote for ${orderData['productName'] ?? 'Order'}',
          type: 'quote_declined',
          referenceId: orderId,
          referenceType: 'order',
        );
      } catch (e) {
        debugPrint('Error sending quote decline notification: $e');
      }
    } catch (e) {
      debugPrint('>>> declineNormalQuote ERROR: $e');
      rethrow;
    }
  }

  Future<void> acceptSplitQuote(String orderId, {String? customerName}) async {
    try {
      isAccepting = true;
      notifyListeners();

      final batch = _db.batch();

      // 1. Update parent order status
      batch.update(_db.collection('orders').doc(orderId), {
        'status': 'customer-confirmed',
        'customerConfirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update all orderParts to active
      final partsSnapshot = await _db
          .collection('orders')
          .doc(orderId)
          .collection('orderParts')
          .get();

      for (final part in partsSnapshot.docs) {
        batch.update(part.reference, {
          'status': 'active',
        });
      }

      await batch.commit();

      debugPrint('>>> split quote accepted: $orderId');

      // Remove from quotes list locally for immediate UI update
      normalQuotesList.removeWhere((o) => o.id == orderId);
      
      isAccepting = false;

      // Switch to Active tab
      ordersTabIndex = activeTabIndex;

      // Send notification to admin
      try {
        final order = getById(orderId);
        await NotificationService.sendNotification(
          recipientId: 'admin',
          recipientType: 'admin',
          title: 'Split Quote Accepted',
          body: '${customerName ?? 'A customer'} accepted the split quote for ${order?.productName ?? 'Order'}',
          type: 'quote_accepted',
          referenceId: orderId,
          referenceType: 'order',
        );

        // Send notification to customer
        if (_auth.currentUser != null) {
          await NotificationService.sendNotification(
            recipientId: _auth.currentUser!.uid,
            recipientType: 'customer',
            title: 'Order Activated',
            body: 'Ap ka order ab active hogyaa hey ab ap es order ki live tracking dek sakty hooo',
            type: 'order_active',
            referenceId: orderId,
            referenceType: 'order',
          );
        }
      } catch (e) {
        debugPrint('Error sending split quote acceptance notifications: $e');
      }
    } catch (e) {
      isAccepting = false;
      notifyListeners();
      debugPrint('acceptSplitQuote ERROR: $e');
      // If it was a permission error, we should probably inform the user or at least stop the loading
      rethrow;
    }
  }

  Future<void> declineSplitQuote(String orderId, {String? customerName}) async {
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

      // Send notification to admin
      try {
        final order = getById(orderId);
        await NotificationService.sendNotification(
          recipientId: 'admin',
          recipientType: 'admin',
          title: 'Split Quote Declined',
          body: '${customerName ?? 'A customer'} declined the split quote for ${order?.productName ?? 'Order'}',
          type: 'quote_declined',
          referenceId: orderId,
          referenceType: 'order',
        );
      } catch (e) {
        debugPrint('Error sending split quote decline notification: $e');
      }
    } catch (e) {
      debugPrint('declineSplitQuote ERROR: $e');
      rethrow;
    }
  }

  Future<void> markOrderAsCompleted(String orderId) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('>>> Order $orderId marked as COMPLETED');

      // Send notification to admin
      try {
        final order = getById(orderId);
        await NotificationService.sendNotification(
          recipientId: 'admin',
          recipientType: 'admin',
          title: 'Split Order Completed',
          body: 'All parts of order ${order?.orderNumber ?? orderId} have been completed.',
          type: 'order_update',
          referenceId: orderId,
          referenceType: 'order',
        );
      } catch (e) {
        debugPrint('Error sending completion notification: $e');
      }
    } catch (e) {
      debugPrint('>>> markOrderAsCompleted ERROR: $e');
    }
  }
}
