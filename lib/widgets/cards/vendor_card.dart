import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/vendor.dart';
import '../../providers/user_provider.dart';
import '../common/rating_stars.dart';
import '../common/verified_badge.dart';

class VendorCard extends StatelessWidget {
  final Vendor vendor;
  final bool horizontal;
  const VendorCard({super.key, required this.vendor, this.horizontal = false});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isSaved = userProvider.isVendorSaved(vendor.id);

    if (horizontal) {
      return _buildHorizontalCard(context, isSaved, userProvider);
    }
    return _buildFullCard(context, isSaved, userProvider);
  }

  Widget _buildHorizontalCard(BuildContext ctx, bool isSaved, UserProvider up) {
    return GestureDetector(
      onTap: () => ctx.push('/vendor/${vendor.id}'),
      child: Container(
        width: 160,
        constraints: const BoxConstraints(minHeight: 220),
        clipBehavior: Clip.hardEdge,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(vendor.avatarUrl),
              ),
              const SizedBox(height: 6),
              Text(
                vendor.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: AppTypography.small.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(vendor.city, style: AppTypography.caption),
              const SizedBox(height: 4),
              RatingStars(rating: vendor.averageRating, compact: true),
              if (vendor.isVerified) ...[
                const SizedBox(height: 4),
                const VerifiedBadge(small: true),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullCard(BuildContext ctx, bool isSaved, UserProvider up) {
    return GestureDetector(
      onTap: () => ctx.push('/vendor/${vendor.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(vendor.avatarUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vendor.name,
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (vendor.isVerified) const VerifiedBadge(small: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textLight),
                        const SizedBox(width: 2),
                        Text('${vendor.city}, ${vendor.province}', style: AppTypography.small),
                      ],
                    ),
                    const SizedBox(height: 4),
                    RatingStars(rating: vendor.averageRating, reviewCount: vendor.totalOrders),
                    const SizedBox(height: 6),
                    Text(
                      vendor.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(color: AppColors.textMedium),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => up.toggleSaveVendor(vendor.id),
                child: Icon(
                  isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isSaved ? Colors.red : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
