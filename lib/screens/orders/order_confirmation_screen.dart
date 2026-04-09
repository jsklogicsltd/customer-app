import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/hunarmand_button.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String orderId;
  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    Future.delayed(const Duration(milliseconds: 200), () => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = context.read<OrderProvider>().getById(widget.orderId);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text('✅', style: TextStyle(fontSize: 60))),
                ),
              ),
              const SizedBox(height: 24),
              Text('Order Placed!', style: AppTypography.h1),
              const SizedBox(height: 8),
              Text(
                'Your order has been placed. The vendor will prepare a quote for you. You\'ll be notified when the price is ready for your review.',
                style: AppTypography.body.copyWith(color: AppColors.textMedium),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _InfoRow(label: 'Order ID', value: widget.orderId),
                    if (order != null) ...[
                      _InfoRow(label: 'Amount', value: formatPKR(order.totalAmount)),
                      const _InfoRow(label: 'Status', value: 'Pending Vendor Confirmation'),
                    ],
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMedium),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Vendor will prepare a quote for your order soon.',
                            style: AppTypography.small.copyWith(color: AppColors.textMedium),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              HunarmandButton(
                label: 'Track Order',
                onPressed: () => context.pushReplacement('/orders/${widget.orderId}'),
              ),
              const SizedBox(height: 12),
              HunarmandButton(
                label: 'Back to Home',
                type: ButtonType.outlined,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.small.copyWith(color: AppColors.textMedium)),
          Text(value, style: AppTypography.small.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
