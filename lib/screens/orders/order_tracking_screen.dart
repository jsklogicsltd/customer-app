import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final OrderModel? order = context.watch<OrderProvider>().getById(orderId);
    if (order == null) {
      return const Scaffold(body: Center(child: Text('Order not found')));
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(order.id, style: AppTypography.h3),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressCard(order),
                _buildTimelineSection(context, order),
                _buildOrderDetailsCard(order),
                _buildVendorCard(order),
                const SizedBox(height: 20),
              ],
            ),
          ),
          _buildStickyBottomButton(context),
        ],
      ),
    );
  }

  Widget _buildProgressCard(OrderModel order) {
    final steps = order.trackingSteps;
    if (steps.isEmpty) return const SizedBox.shrink();

    final currentIdx = () {
      final idx = steps.indexWhere((s) => s.status == 'in_progress');
      if (idx != -1) return idx;
      if (steps.every((s) => s.status == 'completed')) return steps.length;
      return 0;
    }();

    final progress = ((currentIdx) / (steps.length > 1 ? steps.length - 1 : 1) * 100)
        .clamp(0, 100)
        .toInt();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: progress / 100,
                  strokeWidth: 10,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$progress%',
                    style: AppTypography.h1.copyWith(fontSize: 28),
                  ),
                  Text(
                    'Complete',
                    style: AppTypography.small.copyWith(color: AppColors.textMedium),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getCurrentStatusText(order),
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Last updated: Just now',
            style: AppTypography.small.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  String _getCurrentStatusText(OrderModel order) {
    if (order.trackingSteps.isEmpty) return order.status.replaceAll('-', ' ').toUpperCase();
    final steps = order.trackingSteps;
    final inProgress = steps.where((s) => s.status == 'in_progress');
    if (inProgress.isNotEmpty) return inProgress.first.title;
    
    final lastCompleted = steps.lastWhere((s) => s.status == 'completed', orElse: () => steps.first);
    return lastCompleted.title;
  }

  Widget _buildTimelineSection(BuildContext context, OrderModel order) {
    final steps = order.trackingSteps;
    if (steps.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Project Timeline', style: AppTypography.h3),
          const SizedBox(height: 20),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isLast = index == steps.length - 1;
            return _buildTimelineItem(context, step, isLast, order);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, TrackingStep step, bool isLast, OrderModel order) {
    Color stepColor;
    Widget icon;

    switch (step.status) {
      case 'completed':
        stepColor = AppColors.primaryGreen;
        icon = const Icon(Icons.check, size: 14, color: Colors.white);
        break;
      case 'in_progress':
        stepColor = AppColors.gold;
        icon = Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        );
        break;
      case 'pending':
        stepColor = AppColors.textLight;
        icon = const SizedBox();
        break;
      default:
        stepColor = AppColors.textLight;
        icon = const SizedBox();
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side - Stepper Connector
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: step.status == 'pending' ? Colors.transparent : stepColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: stepColor, width: 2),
                ),
                child: Center(child: icon),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: step.status == 'completed' ? AppColors.primaryGreen : AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Right Side - Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(step.title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        _buildStatusChip(step.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.description,
                      style: AppTypography.small.copyWith(color: AppColors.textMedium),
                    ),
                    const SizedBox(height: 8),
                    if (step.status == 'completed' && step.updatedAt != null)
                      Text(
                        'Completed on: ${formatDate(step.updatedAt)}',
                        style: AppTypography.caption.copyWith(color: AppColors.textLight),
                      ),
                    if (step.status == 'in_progress')
                      Text(
                        'Status: In Progress',
                        style: AppTypography.caption.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
                      ),
                    if (step.status == 'pending')
                      Text(
                        'Status: Pending',
                        style: AppTypography.caption.copyWith(color: AppColors.textLight),
                      ),
                    if (step.photos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(step.photos.length, (i) {
                            return Container(
                              width: 60,
                              height: 60,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppColors.bgLight,
                                borderRadius: BorderRadius.circular(8),
                                image: const DecorationImage(
                                  image: NetworkImage('https://picsum.photos/100/100'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: double.infinity,
                                color: Colors.black.withAlpha(100),
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  'Photo ${i + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 8),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                    if (step.title == 'Quote Accepted' && step.status == 'in_progress') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryGreen.withAlpha(80)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Final Price: ${formatPKR(order.confirmedPrice)}',
                              style: AppTypography.h3.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance.collection('orders').doc(order.id).update({
                                        'status': 'customer-confirmed',
                                        'customerConfirmedAt': FieldValue.serverTimestamp(),
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                                    child: const Text('Accept', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _declineQuote(context, order.id),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                    child: const Text('Decline', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _declineQuote(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Quote'),
        content: const Text('Are you sure you want to decline this quote? The order will be cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No, Back')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
                'status': 'cancelled',
                'cancellationReason': 'Customer declined quote',
                'cancelledAt': FieldValue.serverTimestamp(),
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Decline'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'completed':
        color = AppColors.primaryGreen;
        label = 'Completed';
        icon = Icons.check_circle_outline;
        break;
      case 'in_progress':
        color = AppColors.gold;
        label = 'In Progress';
        icon = Icons.radio_button_checked;
        break;
      default:
        color = AppColors.textLight;
        label = 'Pending';
        icon = Icons.radio_button_off;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.inventory_2_outlined, 'Product:', order.productName),
          _buildDetailRow(Icons.numbers, 'Quantity:', '${order.quantity} units'),
          _buildDetailRow(Icons.label_outline, 'Category:', 'Handicrafts'), 
          _buildDetailRow(Icons.payments_outlined, 'Order Value:', formatPKR(order.totalAmount)),
          _buildDetailRow(Icons.calendar_today_outlined, 'Delivery Date:', order.expectedDelivery),
          _buildDetailRow(Icons.location_on_outlined, 'Delivery Location:', order.deliveryAddress),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMedium),
          const SizedBox(width: 12),
          SizedBox(width: 100, child: Text(label, style: AppTypography.small.copyWith(color: AppColors.textMedium))),
          Expanded(child: Text(value, style: AppTypography.small.copyWith(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildVendorCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Assigned Vendor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryGreen.withAlpha(40),
                child: Text(
                  order.vendorName.isNotEmpty ? order.vendorName[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen, fontSize: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.vendorName, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    Text('Karachi, Pakistan', style: AppTypography.small.copyWith(color: AppColors.textMedium)),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        ...List.generate(5, (i) {
                          return const Icon(Icons.star, color: AppColors.gold, size: 14);
                        }),
                        const SizedBox(width: 4),
                        const Text('4.8', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Contact Vendor', style: TextStyle(color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomButton(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: ElevatedButton(
          onPressed: () => _showReportIssueSheet(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text('Report Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  void _showReportIssueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Report an Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              const Text('Please describe the issue you are facing with your order.'),
              const SizedBox(height: 16),
              const TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe issue here...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
