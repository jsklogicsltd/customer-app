import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/order.dart';
import 'order_quote_card.dart';

/// Shows a list of orders that have status 'quote-sent-to-customer'.
/// Each card shows pricing breakdown and accept/reject buttons.
class OrderQuotesList extends StatelessWidget {
  final List<OrderModel> orders;
  final bool isLoading;
  final VoidCallback? onQuoteAccepted;

  const OrderQuotesList({
    super.key,
    required this.orders,
    this.isLoading = false,
    this.onQuoteAccepted,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.bgLight,
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
                style: AppTypography.h3.copyWith(color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'When a quote is sent to you, it will appear here',
                style: AppTypography.small.copyWith(color: AppColors.textMedium),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return OrderQuoteCard(
          order: orders[index],
          onAccepted: onQuoteAccepted,
        );
      },
    );
  }
}
