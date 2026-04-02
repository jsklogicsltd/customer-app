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
      step: map['step'],
      date: map['date'] ?? '',
      note: map['note'] ?? '',
      completed: map['completed'] ?? false,
      current: map['current'] ?? false,
    );
  }
}

class TrackingStep {
  final String title;
  final String description;
  final String status; // 'completed', 'in_progress', 'pending'
  final String? completedDate;
  final String? expectedDate;
  final List<String> photos;

  const TrackingStep({
    required this.title,
    required this.description,
    required this.status,
    this.completedDate,
    this.expectedDate,
    this.photos = const [],
  });

  factory TrackingStep.fromMap(Map<String, dynamic> map) {
    return TrackingStep(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      completedDate: map['completedDate'],
      expectedDate: map['expectedDate'],
      photos: List<String>.from(map['photos'] ?? []),
    );
  }
}

class AppOrder {
  final String id;
  final String productId;
  final String productTitle;
  final String productImage;
  final String vendorId;
  final String vendorName;
  final bool vendorVerified;
  final int quantity;
  final int pricePerUnit;
  final int totalAmount;
  String status;
  final String placedDate;
  final String expectedDelivery;
  final String? deliveredDate;
  final String? cancelledDate;
  final String? cancelReason;
  final List<OrderTimeline> timeline;
  final List<TrackingStep> trackingSteps;
  final int progressPercent;
  final String deliveryAddress;
  final String paymentMethod;
  bool reviewed;

  AppOrder({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.productImage,
    required this.vendorId,
    required this.vendorName,
    required this.vendorVerified,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalAmount,
    required this.status,
    required this.placedDate,
    required this.expectedDelivery,
    this.deliveredDate,
    this.cancelledDate,
    this.cancelReason,
    required this.timeline,
    this.trackingSteps = const [],
    this.progressPercent = 0,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.reviewed = false,
  });

  factory AppOrder.fromMap(Map<String, dynamic> map) {
    return AppOrder(
      id: map['id'],
      productId: map['productId'],
      productTitle: map['productTitle'],
      productImage: map['productImage'],
      vendorId: map['vendorId'],
      vendorName: map['vendorName'],
      vendorVerified: map['vendorVerified'],
      quantity: map['quantity'],
      pricePerUnit: map['pricePerUnit'],
      totalAmount: map['totalAmount'],
      status: map['status'],
      placedDate: map['placedDate'],
      expectedDelivery: map['expectedDelivery'],
      deliveredDate: map['deliveredDate'],
      cancelledDate: map['cancelledDate'],
      cancelReason: map['cancelReason'],
      timeline: (map['timeline'] as List?)
          ?.map((t) => OrderTimeline.fromMap(t))
          .toList() ?? [],
      trackingSteps: (map['trackingSteps'] as List?)
          ?.map((t) => TrackingStep.fromMap(t))
          .toList() ?? [],
      progressPercent: map['progressPercent'] ?? 0,
      deliveryAddress: map['deliveryAddress'],
      paymentMethod: map['paymentMethod'],
      reviewed: map['reviewed'] ?? false,
    );
  }
}
