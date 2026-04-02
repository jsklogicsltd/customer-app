import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/product.dart';
import '../../providers/user_provider.dart';
import '../common/cached_image.dart';
import '../common/rating_stars.dart';
import '../common/verified_badge.dart';
import '../../core/utils/formatters.dart';

class ProductCard extends StatelessWidget {
  final AppProduct product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isSaved = userProvider.isProductSaved(product.id);

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // clipBehavior stops any micro-overflow from rendering visually
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed-height product image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AppCachedImage(
                    url: product.images.first,
                    height: 140,
                    width: double.infinity,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => userProvider.toggleSaveProduct(product.id),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4)],
                      ),
                      child: Icon(
                        isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isSaved ? Colors.red : AppColors.textMedium,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                if (product.vendorVerified)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.verifiedBlue.withAlpha(230),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Icon(Icons.verified, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
            // Content section — Expanded fills remaining cell height
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Fix Option A: maxLines + ellipsis prevents text from pushing price out
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatPKR(product.pricePerUnit),
                      style: AppTypography.priceSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RatingStars(rating: product.rating, compact: true),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.bgLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'MOQ: ${product.moq}',
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    if (product.vendorVerified) ...[
                      const SizedBox(height: 4),
                      const VerifiedBadge(small: true),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
