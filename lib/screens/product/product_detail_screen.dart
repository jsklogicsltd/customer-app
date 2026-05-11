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

import 'package:intl/intl.dart';

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
  void initState() {
    super.initState();
    // Increment product views
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .update({
          'views': FieldValue.increment(1),
          'dailyViews.$today': FieldValue.increment(1),
        })
        .catchError((e) => debugPrint('Error incrementing views: $e'));
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = context.read<VendorProvider>();
    final userProvider = context.watch<UserProvider>();
    final reviewProvider = context.watch<ReviewProvider>();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
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

        return _buildScreen(
          context,
          product,
          isSaved,
          productReviews,
          userProvider,
        );
      },
    );
  }

  Widget _buildScreen(
    BuildContext context,
    Product product,
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
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(220),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: AppColors.textDark,
                ),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => userProvider.toggleSaveProduct(product.id),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(220),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSaved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: isSaved ? Colors.red : AppColors.textDark,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () =>
                          _showFullScreenImage(context, product.mainImageUrl),
                      child: product.mainImageUrl.isNotEmpty
                          ? Image.network(
                              product.mainImageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  height: 320,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFF5A623),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stack) {
                                return Container(
                                  height: 320,
                                  color: Colors.grey.shade100,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: 320,
                              color: Colors.grey.shade100,
                              child: const Icon(
                                Icons.image_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                            ),
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
                // SECTION 1 — Gallery
                if (product.images.isNotEmpty)
                  Container(
                    color: Theme.of(context).cardColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: product.images.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _showFullScreenImage(
                              context,
                              product.images[index],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product.images[index],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey.shade100,
                                    child: const Icon(Icons.image_outlined),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // SECTION 2 — Basic Info
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: AppTypography.h2.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // SECTION 6 — Stock Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: product.isInStock
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              product.isInStock ? 'In Stock' : 'Out of Stock',
                              style: TextStyle(
                                color: product.isInStock
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Description', style: AppTypography.h3),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textMedium,
                        ),
                      ),
                      if (product.fullDescription.isNotEmpty && 
                          product.fullDescription != product.description)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                product.fullDescription,
                                style: AppTypography.body.copyWith(
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // SECTION: Key Features
                if (product.features.isNotEmpty)
                  Container(
                    color: Theme.of(context).cardColor,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KEY FEATURES',
                          style: AppTypography.small.copyWith(
                            color: const Color(0xFFF5A623),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...product.features.map((feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Icon(Icons.circle, size: 6, color: AppColors.primaryGreen),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.textDark,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),

                if (product.features.isNotEmpty) const SizedBox(height: 8),

                // SECTION 3 — Specifications card
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SPECIFICATIONS',
                        style: AppTypography.small.copyWith(
                          color: const Color(0xFFF5A623),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (product.category.isNotEmpty)
                        _specRow('Category', product.category),
                      if (product.productType.isNotEmpty)
                        _specRow('Product Type', product.productType),
                      if (product.material.isNotEmpty)
                        _specRow('Material', product.material),

                      if (product.availableSizes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Sizes',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: product.availableSizes.map((size) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: AppColors.primaryGreen.withAlpha(50),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      size,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.primaryGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                      if (product.colors.isNotEmpty || product.colorNames.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Colors',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Visual Circles
                                  ...product.colors.map((colorStr) {
                                    final trimmed = colorStr.trim();
                                    Color? color;
                                    
                                    try {
                                      if (trimmed.startsWith('#')) {
                                        color = Color(int.parse(trimmed.replaceFirst('#', '0xFF')));
                                      } else if (trimmed.startsWith('0x')) {
                                        color = Color(int.parse(trimmed));
                                      } else if (trimmed.length == 6 && RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(trimmed)) {
                                        color = Color(int.parse('0xFF$trimmed'));
                                      } else if (trimmed.length == 8 && RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(trimmed)) {
                                        color = Color(int.parse('0x$trimmed'));
                                      } else if (int.tryParse(trimmed) != null) {
                                        // Handle raw decimal strings like "4294967295"
                                        color = Color(int.parse(trimmed));
                                      }
                                    } catch (_) {}

                                    if (color != null) {
                                      return Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(15),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      // If it's not a color value, it might be a name that ended up in the colors list
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Text(
                                          trimmed,
                                          style: AppTypography.small.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                      );
                                    }
                                  }),
                                  
                                  // Explicit Color Names
                                  ...product.colorNames.map((name) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F8E9),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFDCEDC8)),
                                    ),
                                    child: Text(
                                      name,
                                      style: AppTypography.small.copyWith(
                                        color: const Color(0xFF388E3C),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )),
                                ],
                              ),
                            ],
                          ),
                        ),

                      if (product.careInstructions.isNotEmpty)
                        _specRow('Care Instructions', product.careInstructions),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // SECTION 7 — Tags
                if (product.searchTags.isNotEmpty)
                  Container(
                    color: Theme.of(context).cardColor,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SEARCH TAGS',
                          style: AppTypography.small.copyWith(
                            color: const Color(0xFFF5A623),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: product.searchTags
                              .map(
                                (tag) => Chip(
                                  label: Text('##$tag'),
                                  backgroundColor: Colors.white,
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF8B6B13),
                                    fontSize: 13,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFD4C18D),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // SECTION 8 — Delivery & Packaging (New)
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DELIVERY & PACKAGING',
                        style: AppTypography.small.copyWith(
                          color: const Color(0xFFF5A623),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _deliveryRow(
                        Icons.local_shipping_outlined,
                        'Delivery To',
                        product.deliveryTo,
                      ),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      _deliveryRow(
                        Icons.access_time,
                        'Lead Time',
                        product.leadTime,
                      ),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      _deliveryRow(
                        Icons.inventory_2_outlined,
                        'MOQ',
                        '${product.moq} units minimum',
                      ),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      _deliveryRow(
                        Icons.redeem_outlined,
                        'Packaging',
                        product.packagingType,
                      ),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      _deliveryRow(
                        Icons.check_circle_outline,
                        'Export Compliant',
                        product.isExportCompliant ? 'Yes' : 'No',
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
                          Text(
                            'Customer Reviews (${product.reviewCount})',
                            style: AppTypography.h3,
                          ),
                          TextButton(
                            onPressed: () =>
                                context.push('/product/${product.id}/reviews'),
                            child: Text(
                              'View All',
                              style: AppTypography.small.copyWith(
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ...productReviews
                          .take(2)
                          .map(
                            (r) => _ReviewItem(
                              name: r.customerName,
                              avatar: r.customerAvatar,
                              rating: r.rating.toDouble(),
                              comment: r.comment,
                              timeAgo: r.weeksAgo,
                            ),
                          ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  context.push(
                    '/chat',
                    extra: {
                      'chatType': 'product',
                      'productId': product.id,
                      'productName': product.name,
                      'vendorId': product.vendorId,
                      'vendorName': product.vendorName,
                    },
                  );
                },
                child: const Text('Contact Support'),
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

  Widget _deliveryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1B5E20)),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTypography.body.copyWith(color: AppColors.textMedium),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for spec rows:
  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: AppColors.textLight),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTypography.small.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String name, avatar, comment, timeAgo;
  final double rating;
  const _ReviewItem({
    required this.name,
    required this.avatar,
    required this.rating,
    required this.comment,
    required this.timeAgo,
  });

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
                    Text(
                      name,
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(timeAgo, style: AppTypography.caption),
                  ],
                ),
                RatingStars(rating: rating, compact: true),
                const SizedBox(height: 4),
                Text(
                  comment,
                  style: AppTypography.small.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
