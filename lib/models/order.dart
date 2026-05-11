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
    String s(dynamic v, [String fb = '']) => v is String ? v : fb;
    return OrderTimeline(
      step:      s(map['step']),
      date:      s(map['date']),   // date may be stored as Timestamp in some orders
      note:      s(map['note']),
      completed: map['completed'] == true || map['completed'] == 1,
      current:   map['current']   == true || map['current']   == 1,
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

  final String? qcStatus;
  final String? qcFeedback;
  final List<String> mediaUrls;
  final int? percentage;

  const TrackingStep({
    required this.step,
    required this.title,
    required this.description,
    required this.status,
    this.updatedAt,
    this.expectedDate,
    this.photos = const [],
    this.qcStatus,
    this.qcFeedback,
    this.mediaUrls = const [],
    this.percentage,
  });

  factory TrackingStep.fromMap(Map<String, dynamic> map) {
    String s(dynamic v, [String fb = '']) => v is String ? v : fb;
    return TrackingStep(
      step:         s(map['step']),
      title:        s(map['title']),
      description:  s(map['description']),
      status:       s(map['status'], 'pending'),
      updatedAt:    map['updatedAt'],
      expectedDate: map['expectedDate'] is String ? map['expectedDate'] as String : null,
      photos:       (map['photos'] as List? ?? []).whereType<String>().toList(),
      qcStatus:     map['qcStatus'] as String?,
      qcFeedback:   map['qcFeedback'] as String?,
      mediaUrls:    (map['mediaUrls'] as List? ?? map['photos'] as List? ?? []).whereType<String>().toList(),
      percentage:   (map['percentage'] as num?)?.toInt(),
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
  final String currentStepId;
  final String currentStepTitle;
  final int progressPercent;
  final String vendorName;
  final bool isSplitOrder;
  final double customerPrice;
  final double vendorQuote;
  final double commissionAmount;
  final dynamic rfqDeadline;
  final dynamic updatedAt;
  final List<String> subOrders;
  final String timelineDuration;
  
  // Split Order Fields
  final double splitTotalVendorCost;
  final double splitTotalCommission;
  final double splitCustomerFinalPrice;


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
    this.currentStepId = '',
    this.currentStepTitle = '',
    this.progressPercent = 0,
    this.vendorName = '',
    this.isSplitOrder = false,
    this.customerPrice = 0,
    this.vendorQuote = 0,
    this.commissionAmount = 0,
    this.rfqDeadline,
    this.updatedAt,
    this.splitTotalVendorCost = 0,
    this.splitTotalCommission = 0,
    this.splitCustomerFinalPrice = 0,
    this.subOrders = const [],
    this.timelineDuration = '',
  });

  // Alias for fromMap to match expected usage in some parts of the app
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    return OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // Getters to fix compilation errors
  String get splitOrderId => id; // Assuming id is used as splitOrderId in some contexts
  String get description => productName; // Fallback to productName

  factory OrderModel.fromMap(Map<String, dynamic> d, String id) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    // Safely convert any field to String — handles Timestamps or other types
    // that may have been stored instead of a plain string in Firestore.
    String toStr(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      if (v is String) return v;
      return fallback; // swallow Timestamps, ints, etc. — return empty string
    }

    return OrderModel(
      id:              id,
      orderNumber:     toStr(d['orderNumber']),
      productName:     toStr(d['productName'], toStr(d['productTitle'], toStr(d['productType'], toStr(d['category'], 'Order #$id')))),
      mainPhotoUrl:    toStr(d['mainPhotoUrl'], toStr(d['productImage'])),
      productId:       toStr(d['productId']),
      vendorId:        toStr(d['vendorId']),
      customerId:      toStr(d['customerId']),
      quantity:        toInt(d['quantity'] ?? d['totalQuantity'] ?? d['qty'] ?? 0),
      unitPrice:       toDouble(d['unitPrice'] ?? d['pricePerUnit']),
      totalAmount:     toDouble(d['totalAmount'] ?? d['confirmedPrice'] ?? d['customerFinalPrice'] ?? d['totalFinalPrice']),
      confirmedPrice:  toDouble(d['confirmedPrice'] ?? d['customerFinalPrice'] ?? d['totalFinalPrice'] ?? d['customerPrice']),
      trackingNumber:  toStr(d['trackingNumber']),
      status:          toStr(d['status']),
      deliveryAddress: toStr(d['deliveryAddress']),
      expectedDelivery: toStr(d['expectedDelivery']),
      quoteId:         toStr(d['quoteId']),
      createdAt:       d['createdAt'],
      vendorName:      toStr(d['vendorName']),
      progressPercent: toInt(d['progressPercent']),
      isSplitOrder:    d['isSplitOrder'] == true || d['isSplitOrder'] == 1 || d['isSplitOrder'] == 'true',
      customerPrice:   toDouble(d['customerPrice']  ?? d['confirmedPrice'] ?? d['customerFinalPrice']),
      vendorQuote:     toDouble(d['vendorQuote']),
      commissionAmount:toDouble(d['commissionAmount']),
      rfqDeadline:     d['rfqDeadline'],
      updatedAt:       d['updatedAt'],
      splitTotalVendorCost: toDouble(d['splitTotalVendorCost']),
      splitTotalCommission: toDouble(d['splitTotalCommission']),
      splitCustomerFinalPrice: toDouble(d['splitCustomerFinalPrice'] ?? d['customerPrice'] ?? d['customerFinalPrice']),
      subOrders:               (d['subOrders'] as List?)?.whereType<String>().toList() ?? [],
      timeline: (d['timeline'] as List?)
          ?.map((v) => OrderTimeline.fromMap(v))
          .toList() ?? [],
      trackingSteps: (d['trackingSteps'] as List?)
          ?.map((v) => TrackingStep.fromMap(v))
          .toList() ?? [],
      currentStepId: toStr(d['currentStepId']),
      currentStepTitle: toStr(d['currentStepTitle']),
      timelineDuration: d['timeline'] is String ? d['timeline'] as String : (d['promisedTimeline']?.toString() ?? d['vendorTimeline']?.toString() ?? ''),
    );
  }
}

class OrderPartModel {
  final String id;
  final int partNumber;
  final int quantity;
  final String unit;
  final String status;
  final String trackingNumber;
  final String courierName;
  final dynamic deliveredAt;
  final String vendorId;
  final String vendorName;
  final List<TrackingStep> trackingSteps;

  OrderPartModel({
    required this.id,
    required this.partNumber,
    required this.quantity,
    this.unit = 'pcs',
    required this.status,
    this.trackingNumber = '',
    this.courierName = '',
    this.deliveredAt,
    this.vendorId = '',
    this.vendorName = '',
    this.trackingSteps = const [],
  });

  factory OrderPartModel.fromFirestoreCustomer(Map<String, dynamic> d, String id) {
    String s(dynamic v, [String fb = '']) => v is String ? v : fb;
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    return OrderPartModel(
      id: id,
      partNumber: toInt(d['partNumber']),
      quantity:   toInt(d['quantity']),
      unit:           s(d['unit'], 'pcs'),
      status:         s(d['status'], 'confirmed'),
      trackingNumber: s(d['trackingNumber']),
      courierName:    s(d['courierName']),
      deliveredAt: d['deliveredAt'],
      vendorId: '', // Masked for Customer App
      vendorName:     s(d['vendorName']),
      trackingSteps: (d['trackingSteps'] as List?)
          ?.map((v) => TrackingStep.fromMap(v))
          .toList() ?? [],
    );
  }
}
