import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../common/cached_image.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isActive;

  const OrderCard({
    super.key,
    required this.order,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (order.status == 'quote-sent') _buildQuoteBanner(context),
            _buildHeader(),
            const Divider(height: 1, thickness: 1),
            _buildBody(),
            if (isActive) ...[
              _buildActiveDetails(),
            ],
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteBanner(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/quotes'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        width: double.infinity,
        color: AppColors.primaryGreen,
        child: Row(
          children: [
            const Icon(Icons.stars, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Your quote is ready! Tap to view.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            order.orderNumber.isEmpty ? 'Order #${order.id.substring(0, 8)}' : order.orderNumber,
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    String label = '';
    Color color = Colors.grey;
    IconData icon = Icons.info_outline;

    switch (order.status) {
      case 'pending-approval':
        label = 'Waiting for Admin Approval';
        color = Colors.orange;
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'vendor-notified':
        label = 'Sent to Vendor';
        color = Colors.blue;
        icon = Icons.send_rounded;
        break;
      case 'vendor-confirmed':
        label = 'Vendor Confirmed';
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'quote-submitted':
        label = 'Quote Under Review';
        color = Colors.orange;
        icon = Icons.rate_review_outlined;
        break;
      case 'quote-sent':
        label = 'Quote Ready — Review Now';
        color = Colors.green;
        icon = Icons.assignment_turned_in_outlined;
        break;
      case 'in-production':
        label = 'In Production';
        color = Colors.blue;
        icon = Icons.precision_manufacturing_outlined;
        break;
      case 'ready-to-ship':
        label = 'Ready to Ship';
        color = Colors.orange;
        icon = Icons.inventory_2_outlined;
        break;
      case 'dispatched':
        label = 'On the Way';
        color = Colors.green;
        icon = Icons.local_shipping_outlined;
        break;
      case 'delivered':
        label = 'Delivered';
        color = Colors.green;
        icon = Icons.verified_rounded;
        break;
      case 'completed':
        label = 'Completed';
        color = AppColors.primaryGreen;
        icon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
      case 'quote-declined':
        label = order.status == 'cancelled' ? 'Cancelled' : 'Quote Declined';
        color = Colors.red;
        icon = Icons.cancel_outlined;
        break;
      default:
        label = order.status.toUpperCase();
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AppCachedImage(
              url: order.mainPhotoUrl,
              width: 70,
              height: 70,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.productName,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Order placed: ${formatDate(order.createdAt)}',
                  style: AppTypography.caption.copyWith(color: AppColors.textMedium),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Qty: ${order.quantity}',
                      style: AppTypography.small.copyWith(color: AppColors.textMedium),
                    ),
                    Text(
                      isActive && order.confirmedPrice > 0 
                        ? formatPKR(order.confirmedPrice)
                        : formatPKR(order.totalAmount),
                      style: AppTypography.price.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDetails() {
    final showTracking = ['dispatched', 'delivered'].contains(order.status);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTracking && order.trackingNumber.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, color: AppColors.textMedium, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Tracking #: ',
                    style: AppTypography.small.copyWith(color: AppColors.textMedium),
                  ),
                  Text(
                    order.trackingNumber,
                    style: AppTypography.small.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ],
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Text('Order Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        _buildTimeline(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTimeline() {
    final steps = [
      'Order Placed',
      'Admin Approved',
      'Vendor Confirmed',
      'Quote Accepted',
      'In Production',
      'Ready to Ship',
      'Dispatched',
      'Delivered',
    ];

    int currentStepIndex = 0;
    switch (order.status) {
      case 'pending-approval': currentStepIndex = 0; break;
      case 'vendor-notified': currentStepIndex = 1; break;
      case 'vendor-confirmed': currentStepIndex = 2; break;
      case 'quote-submitted': 
      case 'quote-sent': currentStepIndex = 3; break;
      case 'in-production': currentStepIndex = 4; break;
      case 'ready-to-ship': currentStepIndex = 5; break;
      case 'dispatched': currentStepIndex = 6; break;
      case 'delivered': 
      case 'completed': currentStepIndex = 7; break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: List.generate(steps.length, (index) {
          final isCompleted = index <= currentStepIndex;
          final isCurrent = index == currentStepIndex;
          final isLast = index == steps.length - 1;

          return IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: isCompleted ? AppColors.primaryGreen : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted ? AppColors.primaryGreen : AppColors.divider,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 10, color: Colors.white)
                          : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: index < currentStepIndex ? AppColors.primaryGreen : AppColors.divider,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      steps[index],
                      style: AppTypography.small.copyWith(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted ? AppColors.textDark : AppColors.textLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.push('/orders/${order.id}'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('View Details'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.push('/chat/${order.vendorId}'),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
