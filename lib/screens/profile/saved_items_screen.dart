import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../widgets/cards/product_card.dart';
import '../../widgets/cards/vendor_card.dart';
import '../../widgets/common/empty_state.dart';

class SavedItemsScreen extends StatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final productProvider = context.watch<ProductProvider>();
    final vendorProvider = context.watch<VendorProvider>();
    final user = userProvider.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final savedProducts = productProvider.getSaved(user.savedProducts);
    final savedVendors = vendorProvider.getSaved(user.savedVendors);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Saved Items'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textMedium,
          indicatorColor: AppColors.primaryGreen,
          tabs: [
            Tab(text: 'Products (${savedProducts.length})'),
            Tab(text: 'Vendors (${savedVendors.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Products
          savedProducts.isEmpty
              ? const EmptyState(emoji: '❤️', title: 'No Saved Products', subtitle: 'Tap the heart icon on any product to save it here')
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72,
                  ),
                  itemCount: savedProducts.length,
                  itemBuilder: (ctx, i) => ProductCard(product: savedProducts[i]),
                ),
          // Vendors
          savedVendors.isEmpty
              ? const EmptyState(emoji: '🏪', title: 'No Saved Vendors', subtitle: 'Follow vendors to see them here')
              : ListView.builder(
                  itemCount: savedVendors.length,
                  itemBuilder: (ctx, i) => VendorCard(vendor: savedVendors[i]),
                ),
        ],
      ),
    );
  }
}
