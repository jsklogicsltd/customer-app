import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/product.dart';
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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('status', isEqualTo: 'live')
          .where('category', isEqualTo: widget.categoryName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }

        final productDocs = snapshot.data?.docs ?? [];
        List<Product> products = productDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return Product.fromMap(data, doc.id);
        }).toList();

        // Further subcategory filter if any
        if (widget.subCategory != null) {
          products = products.where((p) => p.subCategory == widget.subCategory).toList();
        }

        // Apply sorting from productProvider if needed, but local sort is fine here
        switch (_sortBy) {
          case 'price_low':
            products.sort((a, b) => a.pricePerUnit.compareTo(b.pricePerUnit));
            break;
          case 'price_high':
            products.sort((a, b) => b.pricePerUnit.compareTo(a.pricePerUnit));
            break;
          case 'rating':
            products.sort((a, b) => b.rating.compareTo(a.rating));
            break;
          default:
            products.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        }

        return _buildScreen(context, products);
      },
    );
  }

  Widget _buildScreen(BuildContext context, List<Product> products) {
    final productProvider = context.read<ProductProvider>();
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
