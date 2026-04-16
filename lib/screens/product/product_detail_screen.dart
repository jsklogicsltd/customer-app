import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/product.dart';
import '../../models/vendor.dart';
import '../../providers/vendor_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/common/cached_image.dart';
import '../../widgets/common/rating_stars.dart';
import '../../widgets/common/verified_badge.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;
  bool _descExpanded = false;

  @override
  Widget build(BuildContext context) {
    final vendorProvider = context.read<VendorProvider>();
    final userProvider = context.watch<UserProvider>();
    final reviewProvider = context.watch<ReviewProvider>();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('products').doc(widget.productId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }

        final doc = snapshot.data;
        if (doc == null || !doc.exists) {
          return const Scaffold(body: Center(child: Text('Product not found')));
        }

        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        final product = Product.fromMap(data, doc.id);
        final vendor = vendorProvider.getById(product.vendorId);
        final isSaved = userProvider.isProductSaved(product.id);
        final productReviews = reviewProvider.getReviews(product.id);

        return _buildScreen(context, product, vendor, isSaved, productReviews, userProvider);
      },
    );
  }

  Widget _buildScreen(
    BuildContext context,
    Product product,
    Vendor? vendor,
    bool isSaved,
    List productReviews,
    UserProvider userProvider,
  ) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Image gallery as app bar
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
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
                onTap: () => userProvider.toggleSaveProduct(product.id),
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
              background: Stack(
                children: [
                  PageView.builder(
                    itemCount: product.images.length,
                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                    itemBuilder: (ctx, i) => AppCachedImage(url: product.images[i], fit: BoxFit.cover),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(product.images.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentImageIndex == i ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == i ? Colors.white : Colors.white.withAlpha(150),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Info Card
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumb
                      Text('${product.category} > ${product.subCategory}', style: AppTypography.caption),
                      const SizedBox(height: 6),
                      Text(product.title, style: AppTypography.h2),
                      const SizedBox(height: 8),
                      // Price removed per requirement
                      const SizedBox(height: 10),
                      // Tags
                      Wrap(
                        spacing: 6,
                        children: product.tags.map((tag) {
                          final label = tag.replaceAll('-', ' ').toUpperCase();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withAlpha(15),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: AppColors.primaryGreen.withAlpha(80)),
                            ),
                            child: Text(label, style: AppTypography.caption.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => context.push('/product/${product.id}/reviews'),
                        child: RatingStars(rating: product.rating, reviewCount: product.reviewCount),
                      ),
                      const SizedBox(height: 12),
                      // Details grid
                      Row(
                        children: [
                          _DetailBox(label: 'MOQ', value: '${product.moq} units'),
                          const SizedBox(width: 10),
                          _DetailBox(label: 'Lead Time', value: '${product.leadTimeDays} days'),
                          const SizedBox(width: 10),
                          _DetailBox(label: 'Stock', value: product.stock),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Description
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Description', style: AppTypography.h3),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        maxLines: _descExpanded ? 100 : 3,
                        overflow: _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(color: AppColors.textMedium),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _descExpanded = !_descExpanded),
                        child: Text(_descExpanded ? 'Show Less' : 'Read More', style: AppTypography.small.copyWith(color: AppColors.primaryGreen)),
                      ),
                      const Divider(),
                      Text('Features', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...product.features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryGreen, size: 16),
                            const SizedBox(width: 8),
                            Text(f, style: AppTypography.body),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Vendor Card
                if (vendor != null)
                  Container(
                    color: Theme.of(context).cardColor,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sold by', style: AppTypography.small.copyWith(color: AppColors.textMedium)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            CircleAvatar(radius: 24, backgroundImage: NetworkImage(vendor.avatar)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(vendor.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 6),
                                    if (vendor.verified) const VerifiedBadge(small: true),
                                  ]),
                                  Text('${vendor.city}, ${vendor.province}', style: AppTypography.small),
                                  Row(children: [
                                    RatingStars(rating: vendor.rating.toDouble(), compact: true),
                                    Text(' · ${vendor.totalOrders} orders · ${vendor.responseRate}% response', style: AppTypography.caption),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.push('/vendor/${vendor.id}'),
                                icon: const Icon(Icons.store_outlined, size: 16),
                                label: const Text('View Profile'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => context.push('/chat/${vendor.id}', extra: {'productId': product.id}),
                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                label: const Text('WhatsApp'),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Reviews
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Customer Reviews (${product.reviewCount})', style: AppTypography.h3),
                          TextButton(
                            onPressed: () => context.push('/product/${product.id}/reviews'),
                            child: Text('View All', style: AppTypography.small.copyWith(color: AppColors.primaryGreen)),
                          ),
                        ],
                      ),
                      ...productReviews.take(2).map((r) => _ReviewItem(
                        name: r.customerName,
                        avatar: r.customerAvatar,
                        rating: r.rating.toDouble(),
                        comment: r.comment,
                        timeAgo: r.weeksAgo,
                      )),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // Sticky bottom bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push('/chat/${product.vendorId}', extra: {'productId': product.id}),
                child: const Text('Send Enquiry'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.push('/place-order/${product.id}'),
                child: const Text('Place Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailBox extends StatelessWidget {
  final String label, value;
  const _DetailBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMedium)),
            const SizedBox(height: 2),
            Text(value, style: AppTypography.small.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String name, avatar, comment, timeAgo;
  final double rating;
  const _ReviewItem({required this.name, required this.avatar, required this.rating, required this.comment, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 18, backgroundImage: NetworkImage(avatar)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: AppTypography.small.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(timeAgo, style: AppTypography.caption),
                  ],
                ),
                RatingStars(rating: rating, compact: true),
                const SizedBox(height: 4),
                Text(comment, style: AppTypography.small.copyWith(color: AppColors.textMedium)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
