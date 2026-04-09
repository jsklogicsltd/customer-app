import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/product.dart';
import '../../providers/vendor_provider.dart';
import '../../widgets/cards/product_card.dart';
import '../../widgets/cards/vendor_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _query = '';
  late TabController _tabController;

  final List<String> _recentSearches = ['Phulkari', 'Leather bag', 'Pashmina'];
  final List<String> _popularSearches = ["Women's kurta", 'Hand embroidery', 'Export ready', 'Custom 3-piece suit'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = context.read<VendorProvider>();
    final vendors = vendorProvider.search(_query);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search products, vendors...',
            border: InputBorder.none,
            hintStyle: AppTypography.body.copyWith(color: AppColors.textLight),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); },
                  )
                : null,
          ),
          style: AppTypography.body,
        ),
      ),
      body: _query.isEmpty ? _buildInitialState() : _buildSearchResults(vendors),
    );
  }

  Widget _buildSearchResults(List vendors) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('status', isEqualTo: 'live')
          .where('searchTags', arrayContains: _query.toLowerCase())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final productDocs = snapshot.data?.docs ?? [];
        final products = productDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return Product.fromMap(data, doc.id);
        }).toList();

        return _buildResults(products, vendors, context);
      },
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Searches', style: AppTypography.h3),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((s) {
              return GestureDetector(
                onTap: () => _searchCtrl.text = s,
                child: Chip(
                  label: Text(s),
                  avatar: const Icon(Icons.history_rounded, size: 16, color: AppColors.textMedium),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('Popular Searches', style: AppTypography.h3),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSearches.map((s) {
              return GestureDetector(
                onTap: () { setState(() { _query = s; _searchCtrl.text = s; }); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withAlpha(15),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.primaryGreen.withAlpha(80)),
                  ),
                  child: Text(s, style: AppTypography.small.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List products, List vendors, BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: AppColors.textMedium,
            indicatorColor: AppColors.primaryGreen,
            tabs: [
              Tab(text: 'Products (${products.length})'),
              Tab(text: 'Vendors (${vendors.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Products tab
              products.isEmpty
                  ? const Center(child: Text('No products found'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72,
                      ),
                      itemCount: products.length,
                      itemBuilder: (ctx, i) => ProductCard(product: products[i]),
                    ),
              // Vendors tab
              vendors.isEmpty
                  ? const Center(child: Text('No vendors found'))
                  : ListView.builder(
                      itemCount: vendors.length,
                      itemBuilder: (ctx, i) => VendorCard(vendor: vendors[i]),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
