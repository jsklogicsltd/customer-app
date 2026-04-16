import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/split_order.dart';

class ActiveSplitOrderCard extends StatelessWidget {
  final SplitOrderModel splitOrder;

  const ActiveSplitOrderCard({
    super.key,
    required this.splitOrder,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/split-orders/${splitOrder.splitOrderId}');
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.teal.withAlpha(50)),
                  ),
                  child: const Text(
                    'SPLIT ORDER',
                    style: TextStyle(
                        color: Colors.teal,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: AppColors.primaryGreen.withAlpha(50)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 12, color: AppColors.primaryGreen),
                      SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              splitOrder.description,
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.storefront_outlined,
                    size: 16, color: AppColors.textMedium),
                const SizedBox(width: 4),
                Text(
                  '${splitOrder.vendorCount} vendors',
                  style:
                      AppTypography.small.copyWith(color: AppColors.textMedium),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.inventory_2_outlined,
                    size: 16, color: AppColors.textMedium),
                const SizedBox(width: 4),
                Text(
                  'Qty: ${splitOrder.totalQuantity}',
                  style:
                      AppTypography.small.copyWith(color: AppColors.textMedium),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Tap to view tracking',
                    style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded,
                    size: 14, color: AppColors.primaryGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
