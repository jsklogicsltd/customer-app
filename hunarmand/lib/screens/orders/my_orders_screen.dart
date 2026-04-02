import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/cached_image.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/empty_state.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Active', 'Pending', 'Delivered', 'Cancelled'];

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

  List _filterOrders(List orders, String tab) {
    switch (tab) {
      case 'Active': return orders.where((o) => ['confirmed', 'in_production', 'dispatched'].contains(o.status)).toList();
      case 'Pending': return orders.where((o) => o.status == 'pending').toList();
      case 'Delivered': return orders.where((o) => o.status == 'delivered').toList();
      case 'Cancelled': return orders.where((o) => o.status == 'cancelled').toList();
      default: return orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.allOrders;

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
        children: _tabs.map((tab) {
          final filtered = _filterOrders(orders, tab);
          if (filtered.isEmpty) {
            return const EmptyState(
              emoji: '📦',
              title: 'No Orders Yet',
              subtitle: 'Start shopping to see your orders here',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) => _OrderCard(order: filtered[i]),
          );
        }).toList(),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.id, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                StatusChip(status: order.status),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AppCachedImage(url: order.productImage, width: 64, height: 64),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.productTitle, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600), maxLines: 2),
                      Text('by ${order.vendorName}', style: AppTypography.small.copyWith(color: AppColors.textMedium)),
                      const SizedBox(height: 4),
                      Text('Qty: ${order.quantity} · ${formatPKR(order.totalAmount)}', style: AppTypography.small),
                      Text('Placed: ${formatDate(order.placedDate)}', style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Progress bar for active orders
          if (['confirmed', 'in_production', 'dispatched'].contains(order.status)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${order.progressPercent}%',
                        style: AppTypography.small.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      Text(' · ', style: AppTypography.small),
                      Expanded(
                        child: Text(
                          () {
                            final match = (order.trackingSteps as List).where((s) => s.status == 'in_progress');
                            return match.isNotEmpty ? match.first.title : 'Pending';
                          }(),
                          style: AppTypography.small.copyWith(color: AppColors.textMedium),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: order.progressPercent / 100.0,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation(AppColors.primaryGreen),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/orders/${order.id}'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                    child: const Text('Track Order'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/chat/${order.vendorId}'),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
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
