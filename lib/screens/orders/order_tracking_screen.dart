import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../providers/order_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/notification_service.dart';
import '../../models/order.dart';
import '../../widgets/orders/normal_order_tracking_widget.dart';
import '../../features/orders/widgets/split_order_tracking_widget.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  void _shareOrder(OrderModel order) async {
    final status = order.status.replaceAll('-', ' ').toUpperCase();
    final amount = order.confirmedPrice > 0 ? order.confirmedPrice : order.totalAmount;
    final date = formatDate(order.createdAt);

    final shareText = '''
🛍️ KARSAAZI Order Details
──────────────────────────
Order #: ${order.orderNumber}
Product: ${order.productName}
Quantity: ${order.quantity} units
Amount: ${formatPKR(amount)}
Status: $status
Date: $date
──────────────────────────
Track your order on KARSAAZI App''';

    await Share.share(shareText);
  }

  void _showReportBottomSheet(BuildContext context, String uid) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report an Issue', style: AppTypography.h3),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe your issue...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isEmpty) return;
                  await FirebaseFirestore.instance.collection('reports').add({
                    'orderId': orderId,
                    'customerId': uid,
                    'description': controller.text.trim(),
                    'type': 'order_issue',
                    'status': 'open',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  
                  // Trigger admin notification for the report
                  try {
                    final userProvider = context.read<UserProvider>();
                    await NotificationService.sendNotification(
                      recipientId: 'admin',
                      recipientType: 'admin',
                      title: 'New Order Report',
                      body: '${userProvider.user?.name ?? "A customer"} reported an issue with Order #$orderId',
                      type: 'order_report',
                      referenceId: orderId,
                    );
                  } catch (e) {
                    debugPrint('Failed to send report notification: $e');
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Issue reported successfully')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                child: const Text('Submit Report', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCancelOrder(BuildContext context, OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final userProvider = context.read<UserProvider>();
      await context.read<OrderProvider>().cancelOrder(
        orderId,
        'Cancelled by Customer',
        customerName: userProvider.user?.name,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully')),
        );
        context.pop(); // Go back to orders screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final userProvider = context.watch<UserProvider>();
    final OrderModel? order = orderProvider.getById(orderId);
    
    if (order == null) {
      return const Scaffold(body: Center(child: Text('Order not found')));
    }

    final canCancel = ['pending-approval', 'vendor-notified'].contains(order.status);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(order.orderNumber.isNotEmpty ? order.orderNumber : order.id, style: AppTypography.h3),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: () => _shareOrder(order),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Theme.of(context).appBarTheme.foregroundColor),
            onSelected: (value) {
              if (value == 'copy') {
                Clipboard.setData(ClipboardData(text: order.orderNumber));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order number copied!')),
                );
              } else if (value == 'report') {
                _showReportBottomSheet(context, userProvider.user?.id ?? '');
              } else if (value == 'cancel') {
                _handleCancelOrder(context, order);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20),
                    SizedBox(width: 12),
                    Text('Copy Order Number'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_problem_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Report an Issue'),
                  ],
                ),
              ),
              if (canCancel)
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Cancel Order', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: order.isSplitOrder 
          ? SplitOrderTrackingWidget(order: order)
          : NormalOrderTrackingWidget(order: order),
    );
  }
}
