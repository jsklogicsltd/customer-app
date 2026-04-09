import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/review_provider.dart';
import '../../widgets/common/rating_stars.dart';

class AllReviewsScreen extends StatelessWidget {
  final String vendorId;
  const AllReviewsScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context) {
    final reviewProvider = context.watch<ReviewProvider>();
    // Note: In a real app, you might want to fetch reviews for a specific vendor or product.
    // For now, we'll use the provider to get reviews (logic inside provider handles the filter)
    final reviews = reviewProvider.getReviews(vendorId); 
    final avgRating = reviews.isEmpty ? 0.0 : reviews.map((r) => r.rating.toDouble()).reduce((a, b) => a + b) / reviews.length;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(title: const Text('Customer Reviews'), backgroundColor: Colors.white, elevation: 0),
      body: reviews.isEmpty 
        ? const Center(child: Text('No reviews yet'))
        : ListView(
        children: [
          // Summary
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(avgRating.toStringAsFixed(1), style: AppTypography.h1.copyWith(fontSize: 48, color: AppColors.primaryGreen)),
                    RatingStars(rating: avgRating, reviewCount: reviews.length),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((star) {
                      final count = reviews.where((r) => r.rating == star).length;
                      final pct = reviews.isEmpty ? 0.0 : count / reviews.length;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text('$star', style: AppTypography.small),
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: AppColors.bgLight,
                                  valueColor: const AlwaysStoppedAnimation(AppColors.primaryGreen),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('$count', style: AppTypography.caption),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Reviews list
          ...reviews.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 20, backgroundImage: NetworkImage(r.customerAvatar)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(r.customerName, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(r.weeksAgo, style: AppTypography.caption),
                      ]),
                      const SizedBox(height: 4),
                      RatingStars(rating: r.rating.toDouble(), compact: true),
                      const SizedBox(height: 6),
                      Text(r.comment, style: AppTypography.body.copyWith(color: AppColors.textMedium)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
