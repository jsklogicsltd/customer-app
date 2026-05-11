import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../models/chat_message.dart';
import '../../providers/order_provider.dart';
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
        color: Theme.of(context).cardColor,
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
            if (order.status.toLowerCase().replaceAll('_', '-') == 'quote-sent') _buildQuoteBanner(context),
            // _buildHeader(), // Removed header as it's merged into body
            const Divider(height: 1, thickness: 1),
            _buildBody(),
            if (isActive) ...[
              _buildActiveDetails(context),
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
        child: const Row(
          children: [
            Icon(Icons.stars, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your quote is ready! Tap to view.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
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

    // Prioritize dynamic tracking step title if available for active orders
    final normalizedStatus = order.status.toLowerCase().replaceAll('_', '-');
    final activeStatuses = ['active', 'in-production', 'customer-confirmed', 'ready-to-ship'];
    if (order.currentStepTitle.isNotEmpty && activeStatuses.contains(normalizedStatus)) {
      
      // NEW: Check for specific QC statuses in tracking steps for precise badging
      final hasRejected = order.trackingSteps.any((s) => s.status == 'rejected');
      final hasUnderReview = order.trackingSteps.any((s) => s.status == 'under_review');

      if (hasRejected) {
        label = 'Action Required';
        color = Colors.red;
        icon = Icons.warning_amber_rounded;
      } else if (hasUnderReview) {
        label = 'Quality Check';
        color = const Color(0xFFC9A93C);
        icon = Icons.fact_check_outlined;
      } else {
        label = order.currentStepTitle;
        
        // Match colors from screenshot
        if (label.toLowerCase().contains('production')) {
          color = Colors.orange.shade800;
          icon = Icons.precision_manufacturing_outlined;
        } else if (label.toLowerCase().contains('qc')) {
          color = Colors.blue.shade700;
          icon = Icons.fact_check_outlined;
        } else {
          color = AppColors.primaryGreen;
          icon = Icons.local_shipping_outlined;
        }
      }
    } else {
    switch (normalizedStatus) {
        case 'pending-approval':
          label = 'Pending';
          color = Colors.orange;
          icon = Icons.hourglass_empty_rounded;
          break;
        case 'vendor-notified':
          label = 'Notified';
          color = Colors.blue;
          icon = Icons.send_rounded;
          break;
        case 'vendor-confirmed':
          label = 'Confirmed';
          color = Colors.green;
          icon = Icons.check_circle_outline;
          break;
        case 'quote-sent':
        case 'quote-sent-to-customer':
          label = 'Quote Ready';
          color = Colors.orange;
          icon = Icons.receipt_long_rounded;
          break;
        case 'customer-confirmed':
          label = 'Active';
          color = Colors.green;
          icon = Icons.check_circle_outline;
          break;
        case 'in-production':
          label = 'In Production';
          color = Colors.orange.shade800;
          icon = Icons.precision_manufacturing_outlined;
          break;
        case 'in-qc':
          label = 'In QC';
          color = Colors.blue.shade700;
          icon = Icons.fact_check_outlined;
          break;
        case 'completed':
          label = 'Completed';
          color = const Color(0xFF00C853); // Bright green like screenshot
          icon = Icons.check_circle_rounded;
          break;
        case 'cancelled':
        case 'quote-declined':
          label = order.status == 'cancelled' ? 'Cancelled' : 'Declined';
          color = Colors.red;
          icon = Icons.cancel_outlined;
          break;
        default:
          label = order.status.toUpperCase().replaceAll('_', ' ');
          color = Colors.grey;
      }
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
    // Dynamic progress calculation for "Real" tracking
    int calculatedPercent = order.progressPercent;
    
    if (order.status == 'completed' || order.status == 'delivered') {
      calculatedPercent = 100;
    } else {
      // 1. Try to find the latest completed step's percentage (Real tracking)
      if (order.trackingSteps.isNotEmpty) {
        // Find the last completed step
        int lastCompletedIndex = -1;
        for (int i = 0; i < order.trackingSteps.length; i++) {
          if (order.trackingSteps[i].status == 'completed') {
            lastCompletedIndex = i;
          }
        }

        if (lastCompletedIndex != -1) {
          final step = order.trackingSteps[lastCompletedIndex];
          if (step.percentage != null && step.percentage! > 0) {
            calculatedPercent = step.percentage!;
          } else {
            // Fallback: index-based proxy
            calculatedPercent = (((lastCompletedIndex + 1) / order.trackingSteps.length) * 100).round();
          }
        }
      } 
      
      // 2. If it's still 0 or no tracking steps, check timeline
      if (calculatedPercent == 0 && order.timeline.isNotEmpty) {
        final completedTimeline = order.timeline.where((t) => t.completed).length;
        calculatedPercent = ((completedTimeline / order.timeline.length) * 100).round();
      }

      // 3. Fallback based on status stages (The "stages" approach)
      // Updated to match detail view's calculation (e.g., 3/8 steps ≈ 38%)
      if (calculatedPercent == 0 || (calculatedPercent < 10 && order.status == 'in-production')) {
        switch (order.status) {
          case 'pending-approval': calculatedPercent = 12; break;
          case 'vendor-notified': calculatedPercent = 25; break;
          case 'vendor-confirmed': calculatedPercent = 30; break;
          case 'quote-sent': 
          case 'quote-sent-to-customer': calculatedPercent = 35; break;
          case 'customer-confirmed': 
          case 'active': calculatedPercent = 38; break; // Synced with detail view
          case 'in-production': calculatedPercent = 60; break;
          case 'in-qc': calculatedPercent = 75; break;
          case 'ready-to-ship': calculatedPercent = 85; break;
          case 'dispatched': calculatedPercent = 92; break;
        }
      }
      
      // Override if the explicit progressPercent is higher (manual override)
      if (order.progressPercent > calculatedPercent) {
        calculatedPercent = order.progressPercent;
      }
    }

    final progress = (calculatedPercent / 100).clamp(0.0, 1.0);
    final idText = order.orderNumber.isNotEmpty ? order.orderNumber : 'ID: ${order.id.substring(0, 8).toUpperCase()}';

    return Padding(
      padding: const EdgeInsets.all(16),
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
                      'ID: $idText',
                      style: AppTypography.caption.copyWith(color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
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
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF5722)), // Orange like screenshot
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Created: ${formatDate(order.createdAt)}',
                style: AppTypography.caption.copyWith(color: AppColors.textLight),
              ),
              if (order.expectedDelivery.isNotEmpty || order.timelineDuration.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.event_available_outlined, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(
                      order.expectedDelivery.isNotEmpty ? 'Delivery: ${order.expectedDelivery}' : order.timelineDuration,
                      style: AppTypography.caption.copyWith(color: AppColors.textMedium, fontWeight: FontWeight.bold),
                    ),
                    if (order.expectedDelivery.isNotEmpty && order.timelineDuration.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text('(${order.timelineDuration})', style: AppTypography.caption.copyWith(color: AppColors.textLight)),
                    ],
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDetails(BuildContext context) {
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
                color: Theme.of(context).scaffoldBackgroundColor,
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
                    style: AppTypography.small.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        // Removed Order Progress tracking steps from card as per request
        // Percentage line remains in _buildBody
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTimeline(BuildContext context) {
    // If we have a dynamic timeline from the vendor/admin, use it
    if (order.timeline.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: List.generate(order.timeline.length, (index) {
            final item = order.timeline[index];
            final isLast = index == order.timeline.length - 1;

            return IntrinsicHeight(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: item.completed ? AppColors.primaryGreen : Theme.of(context).cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: item.completed ? AppColors.primaryGreen : AppColors.divider,
                            width: 2,
                          ),
                        ),
                        child: item.completed
                            ? const Icon(Icons.check, size: 10, color: Colors.white)
                            : null,
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: item.completed ? AppColors.primaryGreen : AppColors.divider,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.step,
                            style: AppTypography.small.copyWith(
                              fontWeight: item.current ? FontWeight.bold : FontWeight.normal,
                              color: item.completed ? null : AppColors.textLight,
                            ),
                          ),
                          if (item.date.isNotEmpty)
                            Text(
                              item.date,
                              style: AppTypography.caption.copyWith(color: AppColors.textLight),
                            ),
                          if (item.note.isNotEmpty)
                             Text(
                              item.note,
                              style: AppTypography.caption.copyWith(color: AppColors.textMedium, fontStyle: FontStyle.italic),
                            ),
                        ],
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

    // Fallback to status-based hardcoded timeline
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
      case 'quote-sent': 
      case 'quote-sent-to-customer': currentStepIndex = 3; break;
      case 'customer-confirmed':
      case 'active':
        // If we have a currentStepId, try to match it
        if (order.currentStepId == 'raw_material') {
          currentStepIndex = 4;
        } else if (order.currentStepId == 'production') {
          currentStepIndex = 4;
        } else {
          currentStepIndex = 3;
        }
        break;
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
                        color: isCompleted ? AppColors.primaryGreen : Theme.of(context).cardColor,
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
                        color: isCompleted ? null : AppColors.textLight,
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
    final isQuoteReady = ['quote-sent', 'quote-sent-to-customer'].contains(order.status);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          if (isQuoteReady) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAccept(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D5C2F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Accept Quote', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleReject(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
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
                  onPressed: () => context.push(
                    '/chat/order/${order.id}',
                    extra: {
                      'orderId': order.id,
                      'orderNumber': order.orderNumber.isNotEmpty
                          ? order.orderNumber
                          : order.id,
                      'threadId': ChatMessage.buildOrderThreadId(
                        orderId: order.id,
                        customerId: order.customerId,
                      ),
                    },
                  ),
                  icon: const Icon(Icons.support_agent_rounded, size: 16),
                  label: const Text('Support'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context) async {
    try {
      await context.read<OrderProvider>().acceptNormalQuote(order.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote Accepted! Order is now active.'), backgroundColor: AppColors.primaryGreen),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    try {
      await context.read<OrderProvider>().declineNormalQuote(order.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote Declined. Order has been cancelled.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
