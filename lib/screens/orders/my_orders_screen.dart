import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/order_provider.dart';
import '../../providers/quote_provider.dart';
import '../../widgets/orders/order_list.dart';
import '../../widgets/orders/order_quote_card.dart';
import '../../widgets/orders/quote_card.dart';
import '../../widgets/orders/split_quote_card.dart';
import '../../widgets/orders/active_split_order_card.dart';
import '../../widgets/orders/order_card.dart';
import '../../core/constants/app_typography.dart';
import '../../models/order.dart';

import '../../models/quote.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyOrdersScreen extends StatefulWidget {
  final int initialTab;

  const MyOrdersScreen({super.key, this.initialTab = 0});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = [
    'All',
    'Pending',
    'Quotes',
    'Active',
    'Completed',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();

    // Determine initial tab: prefer the provider's initialTabIndex (set by FCM),
    // fall back to the widget constructor parameter (set by GoRouter extra).
    final orderProvider = context.read<OrderProvider>();
    int startTab = widget.initialTab;
    if (orderProvider.ordersTabIndex > 0) {
      startTab = orderProvider.ordersTabIndex;
      // Reset after consuming so it doesn't persist across navigations
      WidgetsBinding.instance.addPostFrameCallback((_) {
        orderProvider.ordersTabIndex = 0;
      });
    }

    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: startTab.clamp(0, _tabs.length - 1),
    );

    // Listen to provider for tab changes
    orderProvider.addListener(_handleProviderTabChange);
  }

  void _handleProviderTabChange() {
    final orderProvider = context.read<OrderProvider>();
    if (orderProvider.ordersTabIndex > 0) {
      final newIndex = orderProvider.ordersTabIndex;
      if (newIndex != _tabController.index) {
        _tabController.animateTo(newIndex);
      }
      // Reset after consuming
      orderProvider.ordersTabIndex = 0;
    }
  }

  @override
  void dispose() {
    context.read<OrderProvider>().removeListener(_handleProviderTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _switchToActiveTab() {
    _tabController.animateTo(3); // Active tab is index 3
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textMedium,
          indicatorColor: AppColors.primaryGreen,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Tab
          Consumer2<OrderProvider, QuoteProvider>(
            builder: (_, op, qp, __) {
              final customQuotes = qp.pendingQuotes;
              final allOrders = op.allOrders;

              // Filter out orders that are better represented by custom quote cards
              final filteredOrders = allOrders.where((o) =>
                !customQuotes.any((q) => q.orderId == o.id)
              ).toList();

              // Combine all items for sorting
              final List<dynamic> allItems = [
                ...customQuotes,
                ...filteredOrders,
              ];

              // Sort by date (descending)
              allItems.sort((a, b) {
                DateTime getDateTime(dynamic item) {
                  if (item is OrderModel) {
                    return (item.updatedAt as Timestamp?)?.toDate() 
                        ?? (item.createdAt as Timestamp?)?.toDate() 
                        ?? DateTime(2000);
                  } else if (item is QuoteModel) {
                    return (item.createdAt as Timestamp?)?.toDate() 
                        ?? DateTime(2000);
                  }
                  return DateTime(2000);
                }
                return getDateTime(b).compareTo(getDateTime(a));
              });

              if (allItems.isEmpty) {
                return OrderList(
                  orders: const [],
                  emptyTitle: 'No orders yet',
                  emptySubtitle: 'Your orders will appear here',
                  emptyIcon: Icons.receipt_long_outlined,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: allItems.length,
                itemBuilder: (context, index) {
                  final item = allItems[index];
                  if (item is OrderModel) {
                    if (item.isSplitOrder) {
                      final status = item.status.toLowerCase().replaceAll('_', '-');
                      final isQuote = ['quote-sent', 'quote-sent-to-customer', 'split-confirmed'].contains(status);
                      if (isQuote) {
                        return SplitQuoteCard(order: item, onAccepted: _switchToActiveTab);
                      } else {
                        return ActiveSplitOrderCard(order: item);
                      }
                    } else {
                      final status = item.status.toLowerCase().replaceAll('_', '-');
                      final isQuote = ['quote-sent', 'quote-sent-to-customer', 'split-confirmed'].contains(status);
                      if (isQuote) {
                        return OrderQuoteCard(
                          order: item,
                          onAccepted: _switchToActiveTab,
                        );
                      }
                      return OrderCard(order: item);
                    }
                  } else {
                    return QuoteCard(quote: item);
                  }
                },
              );
            },
          ),
          // Pending Tab
          Consumer<OrderProvider>(
            builder: (_, p, __) => OrderList(
              orders: p.pendingOrders,
              emptyTitle: 'No pending orders',
              emptySubtitle: 'Your new orders will appear here',
              emptyIcon: Icons.hourglass_empty,
            ),
          ),
          // Quotes Tab — Product Quotes + Custom Request Quotes
          Consumer2<OrderProvider, QuoteProvider>(
            builder: (_, op, qp, __) {
              final orderQuotes = op.normalQuotesList;
              final splitQuotes = op.splitOrderQuotesList;
              final customQuotes = qp.pendingQuotes;

              if (op.isLoading || qp.isLoading) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryGreen));
              }

              if (orderQuotes.isEmpty &&
                  customQuotes.isEmpty &&
                  splitQuotes.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            size: 48,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No quotes yet',
                          style: AppTypography.h3,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'When a quote is sent to you, it will appear here',
                          style: AppTypography.small
                              .copyWith(color: AppColors.textMedium),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...customQuotes.map((q) => QuoteCard(quote: q)),
                  ...orderQuotes
                      .where((o) =>
                          !customQuotes.any((q) => q.orderId == o.id) &&
                          !o.isSplitOrder)
                      .map((o) => OrderQuoteCard(
                            order: o,
                            onAccepted: _switchToActiveTab,
                          )),
                  ...splitQuotes.map((s) => SplitQuoteCard(
                        order: s,
                        onAccepted: _switchToActiveTab,
                      )),
                ],
              );
            },
          ),
          // Active Tab
          Consumer<OrderProvider>(
            builder: (_, p, __) {
              final orders = p.activeOrders;
              final splitOrders = p.activeSplitOrdersList;
              
              debugPrint('>>> UI DIAGNOSTIC: Active Tab rendering ${orders.length} normal orders and ${splitOrders.length} split orders');

              if (orders.isEmpty && splitOrders.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_shipping_outlined,
                              size: 48, color: AppColors.textLight),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No active orders',
                          style: AppTypography.h3,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Orders in production will appear here',
                          style: AppTypography.small
                              .copyWith(color: AppColors.textMedium),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...orders.where((o) => !o.isSplitOrder).map((o) => OrderCard(
                        order: o,
                        isActive: true,
                      )),
                  ...orders.where((o) => o.isSplitOrder).map((s) => ActiveSplitOrderCard(
                        order: s,
                      )),
                ],
              );
            },
          ),
          // Completed Tab
          Consumer<OrderProvider>(
            builder: (_, p, __) => OrderList(
              orders: p.completedOrders,
              emptyTitle: 'No completed orders yet',
              emptyIcon: Icons.check_circle_outline,
            ),
          ),
          // Cancelled Tab
          Consumer<OrderProvider>(
            builder: (_, p, __) => OrderList(
              orders: p.cancelledOrders,
              emptyTitle: 'No cancelled orders',
              emptyIcon: Icons.cancel_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
