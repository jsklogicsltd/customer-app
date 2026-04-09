import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../providers/custom_request_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../widgets/common/hunarmand_button.dart';

class QuoteAcceptConfirmScreen extends StatefulWidget {
  final String requestId;
  const QuoteAcceptConfirmScreen({super.key, required this.requestId});

  @override
  State<QuoteAcceptConfirmScreen> createState() => _QuoteAcceptConfirmScreenState();
}

class _QuoteAcceptConfirmScreenState extends State<QuoteAcceptConfirmScreen> {
  bool _termsAccepted = false;
  String _selectedPayment = 'cod';
  
  @override
  Widget build(BuildContext context) {
    final request = context.read<CustomRequestProvider>().getById(widget.requestId);
    
    if (request == null || request.quote == null) {
      return const Scaffold(body: Center(child: Text('Not found')));
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(title: const Text('Confirm Your Order'), backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm Your Order', style: AppTypography.h2),
            const SizedBox(height: 4),
            Text('Review the final details before confirming', style: AppTypography.small.copyWith(color: AppColors.textMedium)),
            const SizedBox(height: 20),

            // Order Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Summary', style: AppTypography.h3),
                  const SizedBox(height: 12),
                  _SummaryRow(label: 'Product', value: '${request.category} → ${request.subCategory} → ${request.productType}'),
                  _SummaryRow(label: 'Quantity', value: '${request.quantity} units'),
                  _SummaryRow(label: 'Production Time', value: '${request.quote!.productionDays} days'),
                  _SummaryRow(label: 'Expected Delivery', value: request.quote!.expectedDelivery),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total Amount', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatPKR(request.quote!.totalPrice), style: AppTypography.h1.copyWith(color: AppColors.gold, fontSize: 24)),
                          Text('Price includes all charges', style: AppTypography.caption.copyWith(color: AppColors.textMedium)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Delivery Address
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Address', style: AppTypography.h3),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.radio_button_checked, color: AppColors.primaryGreen, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Home', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            Text('House 123, Street 4, F-8/4, Islamabad', style: AppTypography.small),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.add, color: AppColors.primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          Text('Add New Address', style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Payment Method
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Method', style: AppTypography.h3),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    value: 'cod',
                    groupValue: _selectedPayment,
                    onChanged: (v) => setState(() => _selectedPayment = v!),
                    title: Text('Cash on Delivery', style: AppTypography.bodyMedium),
                    activeColor: AppColors.primaryGreen,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  RadioListTile<String>(
                    value: 'online',
                    groupValue: _selectedPayment,
                    onChanged: null, // Disabled
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Online Payment', style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight)),
                        Text('Coming Soon', style: AppTypography.caption.copyWith(color: Colors.grey)),
                      ],
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                  activeColor: AppColors.primaryGreen,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      'I accept the terms and conditions and understand that this is a custom order.',
                      style: AppTypography.small,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Actions
            HunarmandButton(
              label: 'CONFIRM ORDER',
              type: ButtonType.gold,
              onPressed: _termsAccepted ? _handleConfirmOrder : null,
            ),
            const SizedBox(height: 12),
            HunarmandButton(
              label: 'Cancel',
              type: ButtonType.outlined,
              onPressed: () => context.pop(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConfirmOrder() async {
    final request = context.read<CustomRequestProvider>().getById(widget.requestId)!;
    final orderProvider = context.read<OrderProvider>();
    final customRequestProvider = context.read<CustomRequestProvider>();

    try {
      // Create new order object
      final newOrderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      
      final newOrder = OrderModel(
        id: newOrderId,
        productId: request.id,
        orderNumber: '',
        productName: request.productType,
        mainPhotoUrl: request.referenceImages?.firstOrNull ?? 'https://picsum.photos/seed/custom/400/400',
        vendorId: 'v_custom',
        vendorName: 'Hunarmand Custom Shop',
        customerId: request.customerId,
        quantity: request.quantity,
        unitPrice: (request.quote!.totalPrice / request.quantity),
        totalAmount: request.quote!.totalPrice.toDouble(),
        confirmedPrice: request.quote!.totalPrice.toDouble(),
        trackingNumber: '',
        status: 'confirmed',
        deliveryAddress: 'House 123, Street 4, F-8/4, Islamabad',
        expectedDelivery: request.quote!.expectedDelivery,
        quoteId: widget.requestId,
        createdAt: DateTime.now().toIso8601String(),
        timeline: [
          const OrderTimeline(step: 'Order Placed', date: 'Just now', completed: true),
          const OrderTimeline(step: 'Vendor Confirmed', date: 'Just now', completed: true, current: true),
          const OrderTimeline(step: 'Processing', date: '', completed: false),
          const OrderTimeline(step: 'Shipped', date: '', completed: false),
          const OrderTimeline(step: 'Delivered', date: '', completed: false),
        ],
      );

      final realOrderId = await orderProvider.addOrderFromObject(newOrder);
      await customRequestProvider.acceptQuote(widget.requestId, realOrderId);

      if (mounted) {
        // Navigate to shared Order Confirmation Screen
        context.go('/order-confirmation/$realOrderId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.statusCancelled),
        );
      }
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.textMedium))),
          Expanded(child: Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
