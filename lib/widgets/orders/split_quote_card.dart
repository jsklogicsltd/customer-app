import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/split_order.dart';
import '../../providers/order_provider.dart';

class SplitQuoteCard extends StatefulWidget {
  final SplitOrderModel splitOrder;
  final VoidCallback? onAccepted;

  const SplitQuoteCard({
    super.key,
    required this.splitOrder,
    this.onAccepted,
  });

  @override
  State<SplitQuoteCard> createState() => _SplitQuoteCardState();
}

class _SplitQuoteCardState extends State<SplitQuoteCard> {
  final bool _isActionLoading = false;

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
            _buildHeader(),
            const Divider(height: 1),
            _buildProductInfo(),
            const Divider(height: 1),
            _buildPricingBreakdown(),
            const Divider(height: 1),
            _buildActions(context),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          Text(
            widget.splitOrder.orderNumber.isEmpty
                ? 'Order #${widget.splitOrder.splitOrderId.substring(0, 8)}'
                : widget.splitOrder.orderNumber,
            style: AppTypography.small.copyWith(color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.splitOrder.description,
            style:
                AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
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
                '${widget.splitOrder.vendorCount} vendors',
                style:
                    AppTypography.small.copyWith(color: AppColors.textMedium),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.inventory_2_outlined,
                  size: 16, color: AppColors.textMedium),
              const SizedBox(width: 4),
              Text(
                'Qty: ${widget.splitOrder.totalQuantity}',
                style:
                    AppTypography.small.copyWith(color: AppColors.textMedium),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _buildDetailRow(
              'Vendor Quote', formatPKR(widget.splitOrder.combinedQuoteTotal)),
          if (widget.splitOrder.combinedCommission > 0)
            _buildDetailRow(
              'Platform Fee',
              '+ ${formatPKR(widget.splitOrder.combinedCommission)}',
              valueColor: Colors.orange,
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Total',
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                formatPKR(widget.splitOrder.customerFinalPrice),
                style: AppTypography.h3.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '(Inclusive of all charges)',
              style: AppTypography.small.copyWith(color: AppColors.textMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.small.copyWith(color: AppColors.textMedium)),
          Text(
            value,
            style: AppTypography.small.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final isAccepting = context.watch<OrderProvider>().isAccepting;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // ACCEPT button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D5C2F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isAccepting ? null : () => _handleAccept(context),
              child: isAccepting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Accept Quote',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 8),

          // DECLINE button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isAccepting ? null : () => _handleReject(context),
              child: const Text('Decline', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context) async {
    try {
      await context
          .read<OrderProvider>()
          .acceptSplitQuote(widget.splitOrder.splitOrderId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    try {
      await context
          .read<OrderProvider>()
          .declineSplitQuote(widget.splitOrder.splitOrderId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
