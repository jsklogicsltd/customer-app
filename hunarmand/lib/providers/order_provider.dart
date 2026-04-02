import 'package:flutter/material.dart';
import '../data/mock/mock_orders.dart';
import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  late List<AppOrder> _orders;
  int _orderCounter = 1053;

  OrderProvider() {
    _orders = List.from(mockOrdersData);
  }

  List<AppOrder> get allOrders => _orders;

  List<AppOrder> getByStatus(String status) =>
      _orders.where((o) => o.status == status).toList();

  List<AppOrder> get activeOrders => _orders
      .where((o) => ['pending', 'confirmed', 'in_production', 'dispatched'].contains(o.status))
      .toList();

  AppOrder? getById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  String placeOrder({
    required String productId,
    required String productTitle,
    required String productImage,
    required String vendorId,
    required String vendorName,
    required bool vendorVerified,
    required int quantity,
    required int pricePerUnit,
    required String deliveryAddress,
  }) {
    final orderId = 'ORD-$_orderCounter';
    _orderCounter++;

    final newOrder = AppOrder(
      id: orderId,
      productId: productId,
      productTitle: productTitle,
      productImage: productImage,
      vendorId: vendorId,
      vendorName: vendorName,
      vendorVerified: vendorVerified,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      totalAmount: quantity * pricePerUnit,
      status: 'pending',
      placedDate: DateTime.now().toIso8601String().split('T').first,
      expectedDelivery: DateTime.now().add(const Duration(days: 20)).toIso8601String().split('T').first,
      timeline: [
        OrderTimeline(
          step: 'Order Placed',
          date: DateTime.now().toString(),
          completed: true,
        ),
        const OrderTimeline(step: 'Vendor Confirmed', date: 'Pending', completed: false),
        const OrderTimeline(step: 'In Production', date: 'Pending', completed: false),
        const OrderTimeline(step: 'Ready to Ship', date: 'Pending', completed: false),
        const OrderTimeline(step: 'Dispatched', date: 'Pending', completed: false),
        const OrderTimeline(step: 'Delivered', date: 'Pending', completed: false),
      ],
      deliveryAddress: deliveryAddress,
      paymentMethod: 'Cash on Delivery',
    );

    _orders.insert(0, newOrder);
    notifyListeners();
    return orderId;
  }

  void addOrder(AppOrder order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void cancelOrder(String orderId) {
    final order = getById(orderId);
    if (order != null) {
      order.status = 'cancelled';
      notifyListeners();
    }
  }
}
