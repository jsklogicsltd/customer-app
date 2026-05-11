import 'package:flutter/material.dart';
import '../../models/category.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/cached_image.dart';
import '../../widgets/common/shimmer_loading.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../widgets/common/tap_effect.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _searchQuery = "";
  String? _expandedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: categoryProvider.isLoading
          ? const CategoryShimmer()
          : Column(
              children: [
                // Premium Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: AppTapEffect(
                    onTap: () => context.push('/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AppColors.textLight),
                          const SizedBox(width: 12),
                          Text(
                            'What are you looking for?',
                            style: AppTypography.body.copyWith(color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categoryProvider.allCategories.length,
                      itemBuilder: (context, index) {
                        final cat = categoryProvider.allCategories[index];
                        final isExpanded = _expandedCategoryId == cat.id;
                        
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildCategoryItem(cat, isExpanded),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryItem(AppCategory cat, bool isExpanded) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)],
      ),
      child: Column(
        children: [
          // Category header
          AppTapEffect(
            onTap: () {
              context.push('/products', extra: {'categoryName': cat.name});
            },
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(14),
                bottom: isExpanded ? Radius.zero : const Radius.circular(14),
              ),
              child: Stack(
                children: [
                  AppCachedImage(url: cat.image, height: 100, width: double.infinity),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withAlpha(150), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.icon, style: const TextStyle(fontSize: 28)),
                        Text(cat.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text('${cat.productCount} products',
                            style: TextStyle(
                                color: Colors.white.withAlpha(200), fontSize: 12)),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 12,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _expandedCategoryId = isExpanded ? null : cat.id;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Subcategories and Products
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Featured Products',
                          style: AppTypography.small.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMedium)),
                      AppTapEffect(
                        onTap: () => context
                            .push('/products', extra: {'categoryName': cat.name}),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text('View All',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Consumer<ProductProvider>(
                    builder: (context, productProvider, _) {
                      if (productProvider.isLoading) {
                        return SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            itemBuilder: (_, __) =>
                                const ProductShimmer(isHorizontal: true),
                          ),
                        );
                      }
                      final catProducts =
                          productProvider.getProductsByCategory(cat.name);
                      if (catProducts.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                              child: Text('No products found',
                                  style: TextStyle(
                                      fontSize: 12, color: AppColors.textLight))),
                        );
                      }
                      return SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: catProducts.length,
                          itemBuilder: (context, index) {
                            final product = catProducts[index];
                            return Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: 12),
                              child: _SmallProductCard(product: product),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SmallProductCard extends StatelessWidget {
  final dynamic product;
  const _SmallProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(product.mainImageUrl, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
