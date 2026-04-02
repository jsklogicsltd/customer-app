import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/product_provider.dart';
import '../../widgets/cards/product_card.dart';
import '../../widgets/common/empty_state.dart';

class ProductListScreen extends StatefulWidget {
  final String categoryName;
  final String? subCategory;
  const ProductListScreen({super.key, required this.categoryName, this.subCategory});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _sortBy = 'popular';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>()
          .setCategoryFilter(widget.subCategory ?? widget.categoryName);
    });
  }

  @override
  void dispose() {
    context.read<ProductProvider>().clearFilters();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Sort row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('${products.length} products', style: AppTypography.small.copyWith(color: AppColors.textMedium)),
                const Spacer(),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  style: AppTypography.small.copyWith(color: AppColors.textDark),
                  items: const [
                    DropdownMenuItem(value: 'popular', child: Text('Popular')),
                    DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
                    DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
                    DropdownMenuItem(value: 'rating', child: Text('Top Rated')),
                  ],
                  onChanged: (v) {
                    setState(() => _sortBy = v!);
                    productProvider.setSortBy(v!);
                  },
                ),
              ],
            ),
          ),
          // Products
          Expanded(
            child: products.isEmpty
                ? const EmptyState(
                    emoji: '🔍',
                    title: 'No Products Found',
                    subtitle: 'Try a different category or search',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) => ProductCard(product: products[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
