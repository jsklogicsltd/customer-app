class QuoteModel {
  final String id;
  final String orderId;
  final String customerId;
  final String vendorId;
  final String productName;
  final String productPhoto;
  final int quantity;
  final num unitPrice;
  final num commissionAmount;
  final num commissionPercent;
  final num totalPrice; // Original vendor total
  final num customerFinalPrice; // Total with commission
  final int productionDays;
  final dynamic timeline;
  final String notes;
  final String status;
  final dynamic createdAt;

  QuoteModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.vendorId,
    required this.productName,
    required this.productPhoto,
    required this.quantity,
    required this.unitPrice,
    required this.commissionAmount,
    required this.commissionPercent,
    required this.totalPrice,
    required this.customerFinalPrice,
    required this.productionDays,
    this.timeline,
    this.notes = '',
    required this.status,
    this.createdAt,
  });

  factory QuoteModel.fromFirestore(Map<String, dynamic> data, String id) {
    // Robust parsing for production days/timeline
    int parsedDays = 0;
    final dynamic rawDays = data['productionDays'] ?? data['timeline'];
    if (rawDays != null) {
      if (rawDays is int) parsedDays = rawDays;
      else if (rawDays is String) parsedDays = int.tryParse(rawDays) ?? 0;
    }

    return QuoteModel(
      id: id,
      orderId: data['orderId'] ?? '',
      customerId: data['customerId'] ?? '',
      vendorId: data['vendorId'] ?? '',
      productName: data['productName'] ?? '',
      productPhoto: data['productPhoto'] ?? '',
      quantity: data['quantity'] ?? 0,
      unitPrice: (data['unitPrice'] ?? data['pricePerUnit'] ?? 0.0),
      commissionAmount: data['commissionAmount'] ?? 0.0,
      commissionPercent: data['commissionPercent'] ?? data['commissionRate'] ?? 0.0,
      totalPrice: data['totalPrice'] ?? data['vendorTotal'] ?? 0.0,
      customerFinalPrice: data['customerFinalPrice'] ?? data['vendorTotal'] ?? 0.0,
      productionDays: parsedDays,
      timeline: data['timeline'],
      notes: data['notes'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'],
    );
  }
}
