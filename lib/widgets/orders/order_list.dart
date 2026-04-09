import 'package:flutter/material.dart';
import '../../models/order.dart';
import 'order_card.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class OrderList extends StatelessWidget {
  final List<OrderModel> orders;
  final String emptyTitle;
  final String? emptySubtitle;
  final IconData emptyIcon;
  final bool isActiveTab;

  const OrderList({
    super.key,
    required this.orders,
    required this.emptyTitle,
    this.emptySubtitle,
    required this.emptyIcon,
    this.isActiveTab = false,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(emptyIcon, size: 48, color: AppColors.textLight),
              ),
              const SizedBox(height: 20),
              Text(
                emptyTitle,
                style: AppTypography.h3.copyWith(color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              if (emptySubtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  emptySubtitle!,
                  style: AppTypography.small.copyWith(color: AppColors.textMedium),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return OrderCard(
          order: orders[index],
          isActive: isActiveTab,
        );
      },
    );
  }
}
