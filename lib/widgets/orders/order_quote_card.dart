import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../providers/user_provider.dart';
import '../common/cached_image.dart';

/// Card for orders where admin has sent the final quote to the customer.
/// Shows vendor quote, platform fee, customer total, and accept/reject buttons.
class OrderQuoteCard extends StatefulWidget {
  final OrderModel order;
  final VoidCallback? onAccepted;

  const OrderQuoteCard({
    super.key,
    required this.order,
    this.onAccepted,
  });

  @override
  State<OrderQuoteCard> createState() => _OrderQuoteCardState();
}

class _OrderQuoteCardState extends State<OrderQuoteCard> {
  bool _isActionLoading = false;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserProvider>().user?.role ?? 'customer';
    final isAdmin = role == 'admin';
    final isSplitOrder = widget.order.status == 'split-confirmed';

    if (isSplitOrder) {
      return _buildSplitQuoteCard(context);
    }

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
            _buildPricingBreakdown(context),
            if (widget.order.rfqDeadline != null) ...[
              const Divider(height: 1),
              _buildDeadline(),
            ],
            const Divider(height: 1),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitQuoteCard(BuildContext context) {
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
            _buildSplitHeader(),
            const Divider(height: 1),
            _buildProductInfo(),
            const Divider(height: 1),
            _buildSplitPricingBreakdown(context),
            if (widget.order.rfqDeadline != null) ...[
              const Divider(height: 1),
              _buildDeadline(),
            ],
            const Divider(height: 1),
            _buildSplitActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitHeader() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.order.productName.isEmpty
                  ? 'SPLIT ORDER'
                  : widget.order.productName,
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.teal.withAlpha(50)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.call_split_rounded, size: 12, color: Colors.teal),
                SizedBox(width: 4),
                Text(
                  'SPLIT ORDER',
                  style: TextStyle(
                      color: Colors.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitPricingBreakdown(BuildContext context) {
    final role = context.read<UserProvider>().user?.role ?? 'customer';
    final isAdmin = role == 'admin';

    final finalPrice = widget.order.splitCustomerFinalPrice > 0 
        ? widget.order.splitCustomerFinalPrice 
        : widget.order.customerPrice;

    final customerUnitPrice = widget.order.quantity > 0 
        ? (finalPrice / widget.order.quantity) 
        : widget.order.unitPrice;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          if (isAdmin) ...[
            _buildDetailRow('Vendor Price', formatPKR(widget.order.splitTotalVendorCost)),
            if (widget.order.splitTotalCommission > 0)
              _buildDetailRow(
                'Commission',
                '+ ${formatPKR(widget.order.splitTotalCommission)}',
                valueColor: Colors.orange,
              ),
          ] else ...[
            _buildDetailRow(
              'Price per Unit', 
              formatPKR(customerUnitPrice)
            ),
            _buildDetailRow('Qty', 'x ${widget.order.quantity}'),
          ],
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
                formatPKR(finalPrice),
                style: AppTypography.h3.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSplitActions(BuildContext context) {
    if (_isActionLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Accept button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D5C2F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: _isActionLoading ? null : () => _handleSplitAccept(context),
              child: const Text('Accept Quote',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
          ),
          const SizedBox(height: 8),
          // Decline button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isActionLoading ? null : () => _handleSplitReject(context),
              child: const Text('Decline',
                  style: TextStyle(color: Colors.red, fontSize: 15)),
            ),
          ),
        ],
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
            widget.order.orderNumber.isEmpty
                ? 'Order #${widget.order.id.substring(0, 8)}'
                : widget.order.orderNumber,
            style:
                AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange.withAlpha(50)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_rounded,
                    size: 12, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  'Quote Ready',
                  style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
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
              url: widget.order.mainPhotoUrl,
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
                  widget.order.productName,
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${widget.order.quantity}',
                  style:
                      AppTypography.small.copyWith(color: AppColors.textMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown(BuildContext context) {
    final role = context.read<UserProvider>().user?.role ?? 'customer';
    final isAdmin = role == 'admin';

    final customerUnitPrice = widget.order.quantity > 0 
        ? (widget.order.customerPrice / widget.order.quantity) 
        : widget.order.vendorQuote;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          if (isAdmin) ...[
            _buildDetailRow('Vendor Quote', formatPKR(widget.order.vendorQuote)),
            if (widget.order.commissionAmount > 0)
              _buildDetailRow(
                'Platform Fee',
                '+ ${formatPKR(widget.order.commissionAmount)}',
                valueColor: Colors.orange,
              ),
          ] else ...[
            _buildDetailRow(
              'Price per Unit', 
              formatPKR(customerUnitPrice)
            ),
            _buildDetailRow('Qty', 'x ${widget.order.quantity}'),
          ],
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
                formatPKR(widget.order.customerPrice),
                style: AppTypography.h3.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          if (isAdmin) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '(Inclusive of all charges)',
                style: AppTypography.caption.copyWith(color: AppColors.textLight),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeadline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Quote Expires: ',
            style: AppTypography.small.copyWith(color: AppColors.textMedium),
          ),
          Text(
            formatDate(widget.order.rfqDeadline),
            style: AppTypography.small.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
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
    // Use local _isActionLoading so only THIS card shows a spinner,
    // not every card in the list (avoids the global isAccepting flicker).
    if (_isActionLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Accept button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D5C2F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isActionLoading ? null : () => _acceptNormalQuote(widget.order.id),
              child: const Text('Accept Quote',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
          ),

          const SizedBox(height: 8),

          // Decline button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isActionLoading ? null : () => _declineNormalQuote(widget.order.id),
              child: const Text('Decline',
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptNormalQuote(String orderId) async {
    if (!mounted) return;
    setState(() => _isActionLoading = true);
    try {
      final user = context.read<UserProvider>().user;
      await context.read<OrderProvider>().acceptNormalQuote(
        orderId, 
        customerName: user?.name,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote Accepted! Your order is now in production.'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        widget.onAccepted?.call();
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

  Future<void> _declineNormalQuote(String orderId) async {
    if (!mounted) return;
    setState(() => _isActionLoading = true);
    try {
      final user = context.read<UserProvider>().user;
      await context.read<OrderProvider>().declineNormalQuote(
        orderId,
        customerName: user?.name,
      );
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

  Future<void> _handleSplitAccept(BuildContext context) async {
    debugPrint('>>> SPLIT ACCEPT tapped: ${widget.order.id}');
    if (!mounted) return;
    setState(() => _isActionLoading = true);
    try {
      final user = context.read<UserProvider>().user;
      await context.read<OrderProvider>().acceptSplitQuote(
        widget.order.id,
        customerName: user?.name,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Split Quote Accepted! Your order is now confirmed.'),
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

  Future<void> _handleSplitReject(BuildContext context) async {
    final confirmed = await _showRejectConfirmSheet(context, 'Decline this split quote?', 'Are you sure you want to decline this split quote? The order will be cancelled and cannot be undone.');
    if (confirmed != true) return;

    try {
      final user = context.read<UserProvider>().user;
      await context.read<OrderProvider>().declineSplitQuote(
        widget.order.id, 
        customerName: user?.name,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Split quote declined. Order has been cancelled.'),
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
    }
  }

  Future<bool?> _showRejectConfirmSheet(BuildContext context, String title, String subtitle) {
    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.warning_amber_rounded,
                color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.small.copyWith(color: AppColors.textMedium),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Yes, Reject',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
