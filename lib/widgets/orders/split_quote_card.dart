import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';

import '../../providers/order_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/order.dart';
import 'package:go_router/go_router.dart';

class SplitQuoteCard extends StatefulWidget {
  final OrderModel order;
  final VoidCallback? onAccepted;

  const SplitQuoteCard({
    super.key,
    required this.order,
    this.onAccepted,
  });

  @override
  State<SplitQuoteCard> createState() => _SplitQuoteCardState();
}

class _SplitQuoteCardState extends State<SplitQuoteCard> {
  final bool _isActionLoading = false;
  int _quantity = 0;

  @override
  void initState() {
    super.initState();
    _quantity = widget.order.quantity;
    if (_quantity == 0) {
      _fetchQuantity();
    }
  }

  @override
  void didUpdateWidget(SplitQuoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.order.id != oldWidget.order.id || widget.order.quantity != oldWidget.order.quantity) {
      _quantity = widget.order.quantity;
      if (_quantity == 0) {
        _fetchQuantity();
      }
    }
  }

  Future<void> _fetchQuantity() async {
    try {
      final db = FirebaseFirestore.instance;
      final doc = await db.collection('customRequests').doc(widget.order.id).get();
      if (doc.exists) {
        final data = doc.data()!;
        final q = data['quantity'] ?? data['qty'] ?? data['totalQuantity'] ?? data['step1Quantity'];
        if (q != null) {
          int parsedQ = 0;
          if (q is int) parsedQ = q;
          if (q is String) parsedQ = int.tryParse(q) ?? 0;
          if (q is num) parsedQ = q.toInt();
          
          if (parsedQ > 0 && mounted) {
            setState(() {
              _quantity = parsedQ;
            });
          }
        }
      }
    } catch(e) {
      debugPrint('Error fetching quantity for SplitQuoteCard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserProvider>().user?.role ?? 'customer';
    final isAdmin = role == 'admin';

    return InkWell(
      onTap: () {
        context.push('/quote-detail', extra: {
          'order': widget.order,
          'isSplitOrder': true,
        });
      },
      child: Container(
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
            const Divider(height: 1),
            _buildActions(context),
          ],
        ),
      ),
    ));
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
            widget.order.orderNumber.isEmpty
                ? 'Order #${widget.order.id.substring(0, 8)}'
                : widget.order.orderNumber,
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
            widget.order.productName,
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
                'Multiple vendors',
                style:
                    AppTypography.small.copyWith(color: AppColors.textMedium),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.inventory_2_outlined,
                  size: 16, color: AppColors.textMedium),
              const SizedBox(width: 4),
              Text(
                'Qty: $_quantity',
                style:
                    AppTypography.small.copyWith(color: AppColors.textMedium),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown(BuildContext context) {
    final role = context.read<UserProvider>().user?.role ?? 'customer';
    final isAdmin = role == 'admin';

    // Calculate display unit price (including commission for customers)
    final totalQuantity = _quantity > 0 ? _quantity : 1;
    final customerUnitPrice = widget.order.splitCustomerFinalPrice > 0 
        ? widget.order.splitCustomerFinalPrice / totalQuantity 
        : widget.order.confirmedPrice / totalQuantity;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          if (isAdmin) ...[
            _buildDetailRow(
                'Vendor Quote', formatPKR(widget.order.splitTotalVendorCost)),
            if (widget.order.splitTotalCommission > 0)
              _buildDetailRow(
                'Platform Fee',
                '+ ${formatPKR(widget.order.splitTotalCommission)}',
                valueColor: Colors.orange,
              ),
          ] else ...[
            _buildDetailRow(
              'Price per Unit', 
              formatPKR(customerUnitPrice)
            ),
            _buildDetailRow('Qty', 'x $_quantity'),
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
                formatPKR(widget.order.splitCustomerFinalPrice > 0 ? widget.order.splitCustomerFinalPrice : widget.order.confirmedPrice),
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
                style: AppTypography.small.copyWith(color: AppColors.textMedium),
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
      final user = context.read<UserProvider>().user;
      await context
          .read<OrderProvider>()
          .acceptSplitQuote(
            widget.order.id,
            customerName: user?.name,
          );
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
      final user = context.read<UserProvider>().user;
      await context
          .read<OrderProvider>()
          .declineSplitQuote(
            widget.order.id,
            customerName: user?.name,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
