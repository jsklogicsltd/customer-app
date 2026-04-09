import 'package:cloud_firestore/cloud_firestore.dart';

class OrderTimeline {
  final String step;
  final String date;
  final String note;
  final bool completed;
  final bool current;

  const OrderTimeline({
    required this.step,
    required this.date,
    this.note = '',
    required this.completed,
    this.current = false,
  });

  factory OrderTimeline.fromMap(Map<String, dynamic> map) {
    return OrderTimeline(
      step: map['step'] ?? '',
      date: map['date'] ?? '',
      note: map['note'] ?? '',
      completed: map['completed'] ?? false,
      current: map['current'] ?? false,
    );
  }
}

class TrackingStep {
  final String step;
  final String title;
  final String description;
  final String status; // 'completed', 'in_progress', 'pending'
  final dynamic updatedAt;
  final String? expectedDate;
  final List<String> photos;

  const TrackingStep({
    required this.step,
    required this.title,
    required this.description,
    required this.status,
    this.updatedAt,
    this.expectedDate,
    this.photos = const [],
  });

  factory TrackingStep.fromMap(Map<String, dynamic> map) {
    return TrackingStep(
      step: map['step'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      updatedAt: map['updatedAt'],
      expectedDate: map['expectedDate'],
      photos: List<String>.from(map['photos'] ?? []),
    );
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String productName;
  final String mainPhotoUrl;
  final String productId;
  final String vendorId;
  final String customerId;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final double confirmedPrice;
  final String trackingNumber;
  final String status;
  final String deliveryAddress;
  final String expectedDelivery;
  final String quoteId;
  final dynamic createdAt;

  final List<OrderTimeline> timeline;
  final List<TrackingStep> trackingSteps;
  final int progressPercent;
  final String vendorName;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.productName,
    required this.mainPhotoUrl,
    required this.productId,
    required this.vendorId,
    required this.customerId,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.confirmedPrice,
    required this.trackingNumber,
    required this.status,
    required this.deliveryAddress,
    required this.expectedDelivery,
    required this.quoteId,
    this.createdAt,
    this.timeline = const [],
    this.trackingSteps = const [],
    this.progressPercent = 0,
    this.vendorName = '',
  });

  factory OrderModel.fromMap(Map<String, dynamic> d, String id) {
    return OrderModel(
      id:              id,
      orderNumber:     d['orderNumber']     ?? '',
      productName:     d['productName']     ?? d['productTitle'] ?? '',
      mainPhotoUrl:    d['mainPhotoUrl']    ?? d['productImage'] ?? '',
      productId:       d['productId']       ?? '',
      vendorId:        d['vendorId']        ?? '',
      customerId:      d['customerId']      ?? '',
      quantity:        d['quantity']        ?? 0,
      unitPrice:       (d['unitPrice']      ?? d['pricePerUnit'] ?? 0).toDouble(),
      totalAmount:     (d['totalAmount']    ?? 0).toDouble(),
      confirmedPrice:  (d['confirmedPrice'] ?? d['customerPrice'] ?? 0).toDouble(),
      trackingNumber:  d['trackingNumber']  ?? '',
      status:          d['status']          ?? '',
      deliveryAddress: d['deliveryAddress'] ?? '',
      expectedDelivery: d['expectedDelivery'] ?? '',
      quoteId:         d['quoteId']         ?? '',
      createdAt:       d['createdAt'],
      vendorName:      d['vendorName']      ?? '',
      progressPercent: d['progressPercent'] ?? 0,
      timeline: (d['timeline'] as List?)
          ?.map((v) => OrderTimeline.fromMap(v))
          .toList() ?? [],
      trackingSteps: (d['trackingSteps'] as List?)
          ?.map((v) => TrackingStep.fromMap(v))
          .toList() ?? [],
    );
  }
}
