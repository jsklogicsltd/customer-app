import 'package:cloud_firestore/cloud_firestore.dart';

class SplitOrderModel {
  final String splitOrderId;
  final String orderNumber;
  final String description;
  final int vendorCount;
  final int totalQuantity;
  final double customerFinalPrice;
  final String status;
  final String customerId;
  final List<String> subOrders;
  final dynamic createdAt;

  final double combinedQuoteTotal;
  final double combinedCommission;

  SplitOrderModel({
    required this.splitOrderId,
    this.orderNumber = '',
    this.description = '',
    this.vendorCount = 0,
    this.totalQuantity = 0,
    this.customerFinalPrice = 0.0,
    this.combinedQuoteTotal = 0.0,
    this.combinedCommission = 0.0,
    this.status = '',
    this.customerId = '',
    this.subOrders = const [],
    this.createdAt,
  });

  factory SplitOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return SplitOrderModel(
      splitOrderId: doc.id,
      orderNumber: data['orderNumber'] ?? '',
      description: data['description'] ?? data['productName'] ?? 'Split Order',
      vendorCount: data['vendorCount'] ?? 0,
      totalQuantity: data['totalQuantity'] ?? data['quantity'] ?? 0,
      customerFinalPrice: toDouble(data['customerFinalPrice'] ?? data['customerPrice'] ?? data['confirmedPrice']),
      combinedQuoteTotal: toDouble(data['combinedQuoteTotal']),
      combinedCommission: toDouble(data['combinedCommission']),
      status: data['status'] ?? '',
      customerId: data['customerId'] ?? '',
      subOrders: List<String>.from(data['subOrders'] ?? []),
      createdAt: data['createdAt'],
    );
  }
}
