import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/quote.dart';
import '../../providers/quote_provider.dart';
import '../common/cached_image.dart';

class QuoteCard extends StatefulWidget {
  final QuoteModel quote;

  const QuoteCard({
    super.key,
    required this.quote,
  });

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> {
  bool _isActionLoading = false;

  @override
  Widget build(BuildContext context) {
    // Task 3: Always show customerFinalPrice as total price.
    // Includes admin commission.
    final displayPrice = widget.quote.customerFinalPrice > 0 
        ? widget.quote.customerFinalPrice 
        : widget.quote.totalPrice;

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
            _buildProductInfo(),
            const Divider(height: 1),
            _buildPricingDetails(displayPrice),
            const Divider(height: 1),
            _buildTimelineAndNotes(),
            _buildActions(context, displayPrice),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AppCachedImage(
              url: widget.quote.productPhoto,
              width: 60,
              height: 60,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.quote.productName,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Order Qty: ${widget.quote.quantity}',
                  style: AppTypography.small.copyWith(color: AppColors.textMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingDetails(num displayPrice) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _buildDetailRow('Price per Unit', formatPKR(widget.quote.unitPrice)),
          _buildDetailRow('Qty', 'x ${widget.quote.quantity}'),
          if (widget.quote.commissionAmount > 0)
            _buildDetailRow(
              'Admin Commission (${widget.quote.commissionPercent}%)', 
              '+ ${formatPKR(widget.quote.commissionAmount)}',
              valueColor: Colors.orange,
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Final Price',
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                formatPKR(displayPrice),
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
              '(Inclusive of all taxes & commissions)',
              style: AppTypography.caption.copyWith(color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineAndNotes() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Production Timeline: ',
                style: AppTypography.small.copyWith(color: AppColors.textMedium),
              ),
              Text(
                '${widget.quote.productionDays} Days',
                style: AppTypography.small.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ],
          ),
          if (widget.quote.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vendor Notes:',
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textMedium),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.quote.notes,
                    style: AppTypography.small.copyWith(color: AppColors.textDark),
                  ),
                ],
              ),
            ),
          ],
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
          Text(label, style: AppTypography.small.copyWith(color: AppColors.textMedium)),
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

  Widget _buildActions(BuildContext context, num displayPrice) {
    if (_isActionLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleAccept(context, displayPrice),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Accept Quote', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _handleDecline(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context, num finalPrice) async {
    setState(() => _isActionLoading = true);
    try {
      await context.read<QuoteProvider>().acceptQuote(
        widget.quote.id,
        widget.quote.orderId,
        finalPrice,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote Accepted! Your order is now in production.'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleDecline(BuildContext context) async {
    // Task 5: Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Quote?'),
        content: const Text('Are you sure? The order will be cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMedium)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Decline', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);
    try {
      await context.read<QuoteProvider>().declineQuote(widget.quote.id, widget.quote.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote Declined. Order cancelled.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }
}
