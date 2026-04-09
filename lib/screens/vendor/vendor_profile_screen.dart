import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/vendor_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/common/cached_image.dart';
import '../../widgets/common/rating_stars.dart';
import '../../widgets/common/verified_badge.dart';
import '../../widgets/cards/product_card.dart';

class VendorProfileScreen extends StatelessWidget {
  final String vendorId;
  const VendorProfileScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context) {
    final vendor = context.read<VendorProvider>().getById(vendorId);
    final products = context.read<ProductProvider>().getByVendor(vendorId);
    final reviewProvider = context.watch<ReviewProvider>();
    final reviews = reviewProvider.getReviews(vendorId);
    final userProvider = context.watch<UserProvider>();
    final isSaved = userProvider.isVendorSaved(vendorId);

    if (vendor == null) {
      return const Scaffold(body: Center(child: Text('Vendor not found')));
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.white,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withAlpha(220), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textDark),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => userProvider.toggleSaveVendor(vendorId),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(220), shape: BoxShape.circle),
                  child: Icon(
                    isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 20,
                    color: isSaved ? Colors.red : AppColors.textDark,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: AppCachedImage(url: vendor.coverPhotoUrl, fit: BoxFit.cover),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile card
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 36, backgroundImage: NetworkImage(vendor.avatar)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(vendor.name, style: AppTypography.h2),
                                const SizedBox(height: 4),
                                if (vendor.verified)
                                  const VerifiedBadge()
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withAlpha(20),
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(color: Colors.orange.withAlpha(80)),
                                    ),
                                    child: Text('Pending Verification', style: AppTypography.caption.copyWith(color: Colors.orange, fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textLight),
                          Text(' ${vendor.city}, ${vendor.province}', style: AppTypography.small),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time_outlined, size: 14, color: AppColors.textLight),
                          Text(' Member since ${vendor.memberSince}', style: AppTypography.small),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _StatBox(label: 'Rating', value: '${vendor.rating}★'),
                          _StatBox(label: 'Orders', value: '${vendor.totalOrders}'),
                          _StatBox(label: 'Response', value: '${vendor.responseRate}%'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(vendor.about, style: AppTypography.body.copyWith(color: AppColors.textMedium)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6, runSpacing: 6,
                        children: vendor.specialties.map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withAlpha(15),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.primaryGreen.withAlpha(80)),
                          ),
                          child: Text(s, style: AppTypography.small.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w500)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Business details
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Business Details', style: AppTypography.h3),
                      const SizedBox(height: 10),
                      _DetailRow(label: 'Type', value: vendor.businessType),
                      _DetailRow(label: 'Capacity', value: vendor.capacity),
                      _DetailRow(label: 'Export Ready', value: vendor.exportReady ? '✅ Yes' : '❌ No'),
                      _DetailRow(label: 'Languages', value: vendor.languages.join(', ')),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Contact
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact', style: AppTypography.h3),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => context.push('/chat/$vendorId'),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                              label: const Text('WhatsApp'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.phone_outlined, size: 16),
                              label: const Text('Call'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Products
                if (products.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Products', style: AppTypography.h3),
                        TextButton(
                          onPressed: () => context.push('/products', extra: {'categoryName': 'All'}),
                          child: Text('View All', style: AppTypography.small.copyWith(color: AppColors.primaryGreen)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: products.take(4).length,
                      itemBuilder: (ctx, i) => SizedBox(
                        width: 170,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ProductCard(product: products[i]),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Reviews
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Reviews', style: AppTypography.h3),
                          TextButton(
                            onPressed: () => context.push('/product/$vendorId/reviews'),
                            child: Text('View All', style: AppTypography.small.copyWith(color: AppColors.primaryGreen)),
                          ),
                        ],
                      ),
                      if (reviews.isEmpty)
                        const Center(child: Text('No reviews yet'))
                      else
                        ...reviews.take(2).map((r) => Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(radius: 18, backgroundImage: NetworkImage(r.customerAvatar)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.customerName, style: AppTypography.small.copyWith(fontWeight: FontWeight.w600)),
                                    RatingStars(rating: r.rating.toDouble(), compact: true),
                                    Text(r.comment, style: AppTypography.small.copyWith(color: AppColors.textMedium)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
            Text(label, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: AppTypography.small.copyWith(color: AppColors.textMedium))),
          Expanded(child: Text(value, style: AppTypography.small.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
