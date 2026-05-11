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
import '../../providers/category_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/custom_request_provider.dart';
import '../../providers/quote_provider.dart';
import '../../models/order.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/cards/product_card.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/tap_effect.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategoryTab = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final userProvider = context.watch<UserProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final user = userProvider.user;

    if (userProvider.isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen)));
    }

    if (userProvider.error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📡', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 24),
                Text('Connection Error', style: AppTypography.h2),
                const SizedBox(height: 12),
                Text(
                  userProvider.error!,
                  textAlign: TextAlign.center,
                  style:
                      AppTypography.body.copyWith(color: AppColors.textMedium),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => userProvider
                      .signOut(), // Signing out triggers a refresh on auth state
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Login',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏺', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                Text('KARSAAZI',
                    style: AppTypography.h3.copyWith(
                        color: AppColors.primaryGreen, letterSpacing: 1)),
              ],
            ),
            actions: [
              const NotificationBell(),
              GestureDetector(
                onTap: () => context.go('/profile-tab'),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundImage: NetworkImage(user.profileImageUrl),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withAlpha(12), blurRadius: 8)
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            color: AppColors.textLight),
                        const SizedBox(width: 10),
                        Text('Search products...',
                            style: AppTypography.body
                                .copyWith(color: AppColors.textLight)),
                      ],
                    ),
                  ),
                ),

                // Buyer type chip
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.purpleChip.withAlpha(20),
                      borderRadius: BorderRadius.circular(100),
                      border:
                          Border.all(color: AppColors.purpleChip.withAlpha(80)),
                    ),
                    child: Text(
                      '👤 ${_buyerTypeLabel(user.buyerType)} Buyer',
                      style: AppTypography.small.copyWith(
                          color: AppColors.purpleChip,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      _QuickAction(
                          emoji: '🗂',
                          label: 'Categories',
                          color: AppColors.primaryGreen,
                          onTap: () => context.push('/categories')),
                      const SizedBox(width: 10),
                      _QuickAction(
                          icon: Icons.request_quote_outlined,
                          label: 'Quotes',
                          color: AppColors.gold,
                          onTap: () => context.push('/quotes')),
                      const SizedBox(width: 10),
                      _QuickAction(
                          emoji: '📦',
                          label: 'My Orders',
                          color: AppColors.statusDelivered,
                          onTap: () => context.go('/orders-tab')),
                      const SizedBox(width: 10),
                      _QuickAction(
                          emoji: '❤️',
                          label: 'Saved',
                          color: Colors.red,
                          onTap: () => context.push('/saved-items')),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Project Overview Dashboard
                Consumer2<OrderProvider, QuoteProvider>(
                  builder: (context, orderProvider, quoteProvider, child) {
                    return _buildProjectOverview(context, orderProvider, quoteProvider);
                  },
                ),



                // Popular Categories
                _SectionHeader(
                    title: 'Popular Categories',
                    onViewAll: () => context.push('/categories')),
                const SizedBox(height: 10),
                if (categoryProvider.isLoading)
                  const SizedBox(height: 120, child: CategoryShimmer())
                else
                  AnimationLimiter(
                    child: SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categoryProvider.allCategories.length,
                        itemBuilder: (context, index) {
                          final cat = categoryProvider.allCategories[index];
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: FadeInAnimation(
                              child: _buildCategoryCard(context, cat),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 24),


                // Trending Products
                _SectionHeader(
                    title: 'Trending Products',
                    onViewAll: () => context.push('/products',
                        extra: {'categoryName': 'All Products'})),
                if (productProvider.isLoading)
                  const ProductShimmer()
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AnimationLimiter(
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 300,
                        ),
                        itemCount: productProvider.products.take(4).length,
                        itemBuilder: (context, index) {
                          return AnimationConfiguration.staggeredGrid(
                            position: index,
                            columnCount: 2,
                            duration: const Duration(milliseconds: 375),
                            child: ScaleAnimation(
                              child: FadeInAnimation(
                                child: ProductCard(
                                    product: productProvider.products[index]),
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
      case 'individual':
        return 'Personal';
      case 'commercial':
        return 'Business';
      default:
        return 'Standard';
    }
  }

  Widget _buildCategoryCard(BuildContext context, dynamic cat) {
    return AppTapEffect(
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
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
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                '${cat.productCount} products',
                style: TextStyle(
                    color: Colors.white.withAlpha(180), fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectOverview(BuildContext context, OrderProvider orderProvider,
      QuoteProvider quoteProvider) {
    // orderProvider.activeOrders already includes split orders.
    // We should NOT add activeSplitOrdersList.length again.
    final activeCount = orderProvider.activeOrders.length;
    
    final customQuotes = quoteProvider.pendingQuotes;
    final splitQuotes = orderProvider.splitOrderQuotesList;
    
    // Deduplicate: only count normal order quotes that don't have a corresponding custom quote or split quote
    final uniqueOrderQuotesCount = orderProvider.normalQuotesList.where((o) =>
        !customQuotes.any((q) => q.orderId == o.id) &&
        !splitQuotes.any((s) => s.id == o.id)).length;

    // splitQuotes are already part of normalQuotesList. 
    // pendingQuotesCount should be customQuotes + unique items in normalQuotesList.
    final pendingQuotesCount = customQuotes.length + orderProvider.normalQuotesList.where((o) => 
        !customQuotes.any((q) => q.orderId == o.id)).length;

    // Calculate total projects (deduped orders + custom quotes not linked to orders yet)
    // Note: orderProvider.allOrders is already deduped internally
    final totalProjectsCount = orderProvider.allOrders.length + 
        quoteProvider.pendingQuotes.where((q) => 
          !orderProvider.allOrders.any((o) => o.id == q.orderId)).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Project Overview', style: AppTypography.h3),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Live',
                    style: AppTypography.small.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _OverviewCard(
                title: 'Active Projects',
                value: activeCount.toString(),
                icon: Icons.rocket_launch_rounded,
                color: AppColors.primaryGreen,
                onTap: () {
                  orderProvider.ordersTabIndex = orderProvider.activeTabIndex;
                  context.go('/orders-tab');
                },
              ),
              const SizedBox(width: 12),
              _OverviewCard(
                title: 'Pending Quotes',
                value: pendingQuotesCount.toString(),
                icon: Icons.pending_actions_rounded,
                color: AppColors.gold,
                onTap: () {
                  orderProvider.ordersTabIndex = 2; // Quotes tab
                  context.go('/orders-tab');
                },
              ),
              const SizedBox(width: 12),
              _OverviewCard(
                title: 'Total Projects',
                value: totalProjectsCount.toString(),
                icon: Icons.assignment_rounded,
                color: Colors.blueAccent,
                onTap: () {
                  orderProvider.ordersTabIndex = 0; // All tab
                  context.go('/orders-tab');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: color.withAlpha(30), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: AppTypography.h2.copyWith(color: color, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
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
            child: Text('View All →',
                style: AppTypography.small.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {this.emoji,
      this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppTapEffect(
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
              if (icon != null)
                Icon(icon, size: 22, color: color)
              else
                Text(emoji ?? '', style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption
                    .copyWith(color: color, fontWeight: FontWeight.w600),
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
