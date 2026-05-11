import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';

class ActiveSplitOrderCard extends StatelessWidget {
  final OrderModel order;

  const ActiveSplitOrderCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/orders/${order.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.primaryGreen.withAlpha(50), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName,
                        style: AppTypography.h3.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(0, 8).toUpperCase()}',
                        style: AppTypography.caption.copyWith(color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primaryGreen.withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 12, color: AppColors.primaryGreen),
                      const SizedBox(width: 4),
                      Text(
                        order.status.toUpperCase(),
                        style: const TextStyle(color: AppColors.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildProgressSection(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storefront_outlined, size: 16, color: AppColors.textMedium),
                    const SizedBox(width: 4),
                    Text(
                      'Multiple vendors',
                      style: AppTypography.small.copyWith(color: AppColors.textMedium),
                    ),
                  ],
                ),
                Text(
                  'Qty: ${order.quantity}',
                  style: AppTypography.small.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_outlined, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(
                      'Delivery: ${_getDeliveryDate()}',
                      style: AppTypography.caption.copyWith(color: AppColors.textMedium),
                    ),
                    if (order.timelineDuration.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: AppColors.textLight)),
                      const SizedBox(width: 8),
                      Text(
                        order.timelineDuration,
                        style: AppTypography.caption.copyWith(color: AppColors.textMedium, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('View Tracking',
                        style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        size: 14, color: AppColors.primaryGreen),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDeliveryDate() {
    if (order.expectedDelivery.isNotEmpty) return order.expectedDelivery;
    // Fallback logic if we have a timelineDuration and createdAt
    if (order.timelineDuration.isNotEmpty) {
      final match = RegExp(r'(\d+)').firstMatch(order.timelineDuration);
      if (match != null) {
        final days = int.tryParse(match.group(1)!);
        if (days != null) {
          DateTime created;
          if (order.createdAt is Timestamp) created = (order.createdAt as Timestamp).toDate();
          else if (order.createdAt is DateTime) created = order.createdAt;
          else created = DateTime.now();
          
          final date = created.add(Duration(days: days));
          return '${date.day} ${formatDate(order.createdAt).split(' ').last} ${date.year}';
        }
      }
    }
    return formatDate(order.createdAt);
  }

  Widget _buildProgressSection() {
    int calculatedPercent = order.progressPercent;
    final normalizedStatus = order.status.toLowerCase().replaceAll('_', '-');

    if (normalizedStatus == 'completed' || normalizedStatus == 'delivered') {
      calculatedPercent = 100;
    } else {
      // 1. Check timeline fallback if progress is 0
      if (calculatedPercent == 0 && order.timeline.isNotEmpty) {
        final completedTimeline = order.timeline.where((t) => t.completed).length;
        calculatedPercent =
            ((completedTimeline / order.timeline.length) * 100).round();
      }

      // 2. Fallback based on status stages if still 0 or very low for active status
      if (calculatedPercent == 0 ||
          (calculatedPercent < 10 &&
              (normalizedStatus == 'in-production' ||
                  normalizedStatus == 'active' ||
                  normalizedStatus == 'customer-confirmed'))) {
        switch (normalizedStatus) {
          case 'pending-approval':
            calculatedPercent = 12;
            break;
          case 'vendor-notified':
            calculatedPercent = 25;
            break;
          case 'vendor-confirmed':
            calculatedPercent = 30;
            break;
          case 'quote-sent':
          case 'quote-sent-to-customer':
            calculatedPercent = 35;
            break;
          case 'customer-confirmed':
            calculatedPercent = 11;
            break;
          case 'active':
            calculatedPercent = 38;
            break;
          case 'in-production':
            calculatedPercent = 60;
            break;
          case 'in-qc':
            calculatedPercent = 75;
            break;
          case 'ready-to-ship':
            calculatedPercent = 85;
            break;
          case 'dispatched':
            calculatedPercent = 92;
            break;
        }
      }
    }

    final progress = (calculatedPercent / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overall Progress',
              style: AppTypography.small.copyWith(color: AppColors.textLight),
            ),
            Text(
              '$calculatedPercent%',
              style: AppTypography.small.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.divider.withAlpha(50),
            valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFF5722)), // Orange to match other cards
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Created: ${formatDate(order.createdAt)}',
          style: AppTypography.caption.copyWith(color: AppColors.textLight),
        ),
      ],
    );
  }
}
