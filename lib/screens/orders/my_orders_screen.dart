import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/order_provider.dart';
import '../../providers/quote_provider.dart';
import '../../widgets/orders/order_list.dart';
import '../../widgets/orders/quotes_list.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Pending', 'Quotes', 'Active', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.white,
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
          Consumer<OrderProvider>(
            builder: (_, p, __) => OrderList(
              orders: p.allOrders,
              emptyTitle: 'No orders yet',
              emptySubtitle: 'Your orders will appear here',
              emptyIcon: Icons.receipt_long_outlined,
            ),
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
          // Quotes Tab
          Consumer<QuoteProvider>(
            builder: (_, p, __) => QuotesList(
              quotes: p.pendingQuotes,
              isLoading: p.isLoading,
            ),
          ),
          // Active Tab
          Consumer<OrderProvider>(
            builder: (_, p, __) => OrderList(
              orders: p.activeOrders,
              emptyTitle: 'No active orders',
              emptySubtitle: 'Orders in production will appear here',
              emptyIcon: Icons.local_shipping_outlined,
              isActiveTab: true,
            ),
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
