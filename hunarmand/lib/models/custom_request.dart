class TeamQuote {
  final int totalPrice;
  final int productionDays;
  final String expectedDelivery;
  final String teamNote;

  const TeamQuote({
    required this.totalPrice,
    required this.productionDays,
    required this.expectedDelivery,
    this.teamNote = '',
  });

  factory TeamQuote.fromMap(Map<String, dynamic> map) {
    return TeamQuote(
      totalPrice: map['totalPrice'] as int,
      productionDays: map['productionDays'] as int,
      expectedDelivery: map['expectedDelivery'] as String,
      teamNote: map['teamNote'] as String? ?? '',
    );
  }
}

class RequestTimeline {
  final String step;
  final String date;
  final bool completed;
  final bool current;

  const RequestTimeline({
    required this.step,
    required this.date,
    required this.completed,
    this.current = false,
  });

  factory RequestTimeline.fromMap(Map<String, dynamic> map) {
    return RequestTimeline(
      step: map['step'],
      date: map['date'] ?? '',
      completed: map['completed'] ?? false,
      current: map['current'] ?? false,
    );
  }
}

class CustomRequest {
  final String id;
  final String category;
  final String subCategory;
  final String productType;
  final String description;
  final int quantity;
  final List<String> sizes;
  final String color;
  final String material;
  final int budgetMin;
  final int budgetMax;
  final String deadline;
  final String deliveryType;
  final String packaging;
  String status;
  final String submittedDate;
  final List<String>? referenceImages;
  final List<RequestTimeline> timeline;
  final TeamQuote? quote;
  final String? confirmedOrderId;

  CustomRequest({
    required this.id,
    required this.category,
    required this.subCategory,
    required this.productType,
    required this.description,
    required this.quantity,
    required this.sizes,
    required this.color,
    required this.material,
    required this.budgetMin,
    required this.budgetMax,
    required this.deadline,
    required this.deliveryType,
    required this.packaging,
    required this.status,
    required this.submittedDate,
    this.referenceImages,
    required this.timeline,
    this.quote,
    this.confirmedOrderId,
  });

  factory CustomRequest.fromMap(Map<String, dynamic> map) {
    return CustomRequest(
      id: map['id'],
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      productType: map['productType'] ?? '',
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 1,
      sizes: List<String>.from(map['sizes'] ?? []),
      color: map['color'] ?? '',
      material: map['material'] ?? '',
      budgetMin: map['budgetMin'] ?? 0,
      budgetMax: map['budgetMax'] ?? 0,
      deadline: map['deadline'] ?? '',
      deliveryType: map['deliveryType'] ?? 'domestic',
      packaging: map['packaging'] ?? 'standard',
      status: map['status'] ?? 'pending',
      submittedDate: map['submittedDate'] ?? '',
      referenceImages: map['referenceImages'] != null
          ? List<String>.from(map['referenceImages'])
          : null,
      timeline: map['timeline'] != null
          ? (map['timeline'] as List)
              .map((t) => RequestTimeline.fromMap(t))
              .toList()
          : [],
      quote: map['quote'] != null ? TeamQuote.fromMap(map['quote']) : null,
      confirmedOrderId: map['confirmedOrderId'],
    );
  }
}
