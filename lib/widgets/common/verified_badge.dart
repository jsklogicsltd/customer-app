import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class VerifiedBadge extends StatelessWidget {
  final bool small;
  const VerifiedBadge({super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 3),
      decoration: BoxDecoration(
        color: AppColors.verifiedBlue.withAlpha(20),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.verifiedBlue.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: AppColors.verifiedBlue, size: small ? 12 : 14),
          const SizedBox(width: 3),
          Text(
            'Verified',
            style: (small ? AppTypography.caption : AppTypography.small).copyWith(
              color: AppColors.verifiedBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
