import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/product_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_provider.dart';
import '../../data/mock/mock_categories.dart';
import '../../widgets/cards/product_card.dart';
import '../../widgets/cards/vendor_card.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate loading with shimmer
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final vendorProvider = context.watch<VendorProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textDark),
              onPressed: () {},
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏺', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                Text('KARSAAZI', style: AppTypography.h3.copyWith(color: AppColors.primaryGreen, letterSpacing: 1)),
              ],
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textDark),
                    onPressed: () => context.push('/notifications'),
                  ),
                  if (notifProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            '${notifProvider.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundImage: NetworkImage(user.avatar),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppColors.textLight),
                        const SizedBox(width: 10),
                        Text('Search products, vendors...', style: AppTypography.body.copyWith(color: AppColors.textLight)),
                      ],
                    ),
                  ),
                ),

                // Buyer type chip
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.purpleChip.withAlpha(20),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.purpleChip.withAlpha(80)),
                    ),
                    child: Text(
                      '👤 ${_buyerTypeLabel(user.buyerType)} Buyer',
                      style: AppTypography.small.copyWith(color: AppColors.purpleChip, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      _QuickAction(emoji: '🗂', label: 'Categories', color: AppColors.primaryGreen, onTap: () {}),
                      const SizedBox(width: 10),
                      _QuickAction(emoji: '🤖', label: 'Custom Request', color: AppColors.gold, onTap: () => context.push('/custom-request/step1')),
                      const SizedBox(width: 10),
                      _QuickAction(emoji: '📦', label: 'My Orders', color: AppColors.statusDelivered, onTap: () {}),
                      const SizedBox(width: 10),
                      _QuickAction(emoji: '❤️', label: 'Saved', color: Colors.red, onTap: () => context.push('/saved-items')),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Popular Categories
                _SectionHeader(title: 'Popular Categories', onViewAll: () {}),
                const SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: mockCategories.length,
                    itemBuilder: (context, index) {
                      final cat = mockCategories[index];
                      return GestureDetector(
                        onTap: () => context.push('/products', extra: {'categoryName': cat.name}),
                        child: Container(
                          width: 130,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(cat.image),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withAlpha(180)],
                              ),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(cat.icon, style: const TextStyle(fontSize: 22)),
                                Text(
                                  cat.name,
                                  maxLines: 2,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${cat.productCount} products',
                                  style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Top Vendors
                _SectionHeader(title: 'Top Verified Vendors', onViewAll: () {}),
                const SizedBox(height: 10),
                SizedBox(
                  height: 260,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: vendorProvider.allVendors.length,
                    itemBuilder: (context, index) {
                      return VendorCard(vendor: vendorProvider.allVendors[index], horizontal: true);
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Trending Products
                _SectionHeader(title: 'Trending Products', onViewAll: () => context.push('/products', extra: {'categoryName': 'All Products'})),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimationLimiter(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 300,
                      ),
                      itemCount: productProvider.allProducts.take(4).length,
                      itemBuilder: (context, index) {
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          columnCount: 2,
                          child: ScaleAnimation(
                            child: FadeInAnimation(
                              child: ProductCard(product: productProvider.allProducts[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),


                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buyerTypeLabel(String type) {
    switch (type) {
      case 'business': return 'Business';
      case 'bulk': return 'Bulk/Export';
      default: return 'Individual';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;
  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.h3),
          TextButton(
            onPressed: onViewAll,
            child: Text('View All →', style: AppTypography.small.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String emoji, label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.emoji, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
