class ReviewModel {
  final String id;
  final String vendorId;
  final String orderId;
  final String customerName;
  final String customerAvatar;
  final int rating;
  final String comment;
  final String date;
  final String weeksAgo;

  const ReviewModel({
    required this.id,
    required this.vendorId,
    required this.orderId,
    required this.customerName,
    required this.customerAvatar,
    required this.rating,
    required this.comment,
    required this.date,
    required this.weeksAgo,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'],
      vendorId: map['vendorId'],
      orderId: map['orderId'],
      customerName: map['customerName'],
      customerAvatar: map['customerAvatar'],
      rating: map['rating'],
      comment: map['comment'],
      date: map['date'],
      weeksAgo: map['weeksAgo'],
    );
  }
}
