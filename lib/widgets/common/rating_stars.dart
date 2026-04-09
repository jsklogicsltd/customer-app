import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double size;
  final bool compact;

  const RatingStars({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = 14,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: Colors.amber, size: size),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: AppTypography.small.copyWith(fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        if (reviewCount != null && !compact) ...[
          Text(
            ' ($reviewCount)',
            style: AppTypography.small.copyWith(color: AppColors.textLight),
          ),
        ],
      ],
    );
  }
}
