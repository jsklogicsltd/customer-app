import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/hunarmand_button.dart';
import '../../widgets/common/cached_image.dart';

class PlaceOrderScreen extends StatefulWidget {
  final String productId;
  const PlaceOrderScreen({super.key, required this.productId});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  int _quantity = 1;
  int _selectedAddressIndex = 0;
  bool _callBeforeDelivery = false;
  bool _leaveAtGate = false;
  bool _termsAccepted = false;
  final _specialInstructionsCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _specialInstructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = context.read<ProductProvider>().getById(widget.productId);
    final userProvider = context.read<UserProvider>();
    final addresses = userProvider.addresses;

    if (product == null) return const Scaffold(body: Center(child: Text('Product not found')));

    final totalAmount = _quantity * product.pricePerUnit;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(title: const Text('Place Order'), backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product summary
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AppCachedImage(url: product.images.first, width: 72, height: 72),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600), maxLines: 2),
                        Text('by ${product.vendorName}', style: AppTypography.small.copyWith(color: AppColors.textMedium)),
                        Text(formatPKR(product.pricePerUnit), style: AppTypography.priceSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Quantity Selector
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quantity', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () { if (_quantity > product.moq) setState(() => _quantity--); },
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        color: AppColors.primaryGreen,
                      ),
                      Text('$_quantity', style: AppTypography.h2),
                      IconButton(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: AppColors.primaryGreen,
                      ),
                      if (_quantity < product.moq)
                        Text('  MOQ: ${product.moq} units minimum', style: AppTypography.small.copyWith(color: AppColors.statusCancelled)),
                    ],
                  ),
                ],
              ),
            ),

            // Delivery Address
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Address', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ...addresses.asMap().entries.map((e) {
                    final i = e.key;
                    final addr = e.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAddressIndex = i),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedAddressIndex == i ? AppColors.primaryGreen.withAlpha(15) : AppColors.bgLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedAddressIndex == i ? AppColors.primaryGreen : AppColors.divider,
                            width: _selectedAddressIndex == i ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              addr.label == 'Home' ? Icons.home_outlined : Icons.work_outline_rounded,
                              color: _selectedAddressIndex == i ? AppColors.primaryGreen : AppColors.textMedium,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(addr.label, style: AppTypography.small.copyWith(fontWeight: FontWeight.w600)),
                                  Text(addr.address, style: AppTypography.small.copyWith(color: AppColors.textMedium)),
                                ],
                              ),
                            ),
                            if (_selectedAddressIndex == i)
                              const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 20),
                          ],
                        ),
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                    label: const Text('+ Add New Address'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primaryGreen),
                  ),
                ],
              ),
            ),

            // Delivery prefs
            Container(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _callBeforeDelivery,
                    onChanged: (v) => setState(() => _callBeforeDelivery = v!),
                    title: Text('Call before delivery', style: AppTypography.body),
                    activeColor: AppColors.primaryGreen,
                  ),
                  CheckboxListTile(
                    value: _leaveAtGate,
                    onChanged: (v) => setState(() => _leaveAtGate = v!),
                    title: Text('Leave at gate if not home', style: AppTypography.body),
                    activeColor: AppColors.primaryGreen,
                  ),
                ],
              ),
            ),

            // Special instructions
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Special Instructions (Optional)', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _specialInstructionsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Any special requirements...'),
                  ),
                ],
              ),
            ),

            // Order summary
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Summary', style: AppTypography.h3),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Products (${_quantity} × ${formatPKR(product.pricePerUnit)})', style: AppTypography.body.copyWith(color: AppColors.textMedium)),
                      Text(formatPKR(totalAmount), style: AppTypography.bodyMedium),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      Text(formatPKR(totalAmount), style: AppTypography.price),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.access_time_outlined, size: 16, color: AppColors.textMedium),
                      Text('  Expected Delivery: ${product.leadTimeDays} days', style: AppTypography.small),
                    ]),
                  ),
                ],
              ),
            ),

            // Payment
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Method', style: AppTypography.h3),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryGreen),
                    ),
                    child: Row(children: [
                      const Icon(Icons.payments_outlined, color: AppColors.primaryGreen),
                      const SizedBox(width: 10),
                      Text('Cash on Delivery', style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryGreen)),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.credit_card_outlined, color: AppColors.textLight),
                      const SizedBox(width: 10),
                      Text('Online Payment', style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                        child: Text('Coming Soon', style: AppTypography.caption.copyWith(color: Colors.orange)),
                      ),
                    ]),
                  ),
                ],
              ),
            ),

            // Terms
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: CheckboxListTile(
                value: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v!),
                title: Text('I agree to the Terms & Conditions', style: AppTypography.small),
                activeColor: AppColors.primaryGreen,
                contentPadding: EdgeInsets.zero,
              ),
            ),

            // Confirm button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: HunarmandButton(
                label: 'CONFIRM ORDER',
                isLoading: _isLoading,
                onPressed: _quantity < product.moq || !_termsAccepted
                    ? null
                    : () async {
                        setState(() => _isLoading = true);
                        await Future.delayed(const Duration(milliseconds: 600));
                        if (!mounted) return;
                        final orderId = context.read<OrderProvider>().placeOrder(
                          productId: product.id,
                          productTitle: product.title,
                          productImage: product.images.first,
                          vendorId: product.vendorId,
                          vendorName: product.vendorName,
                          vendorVerified: product.vendorVerified,
                          quantity: _quantity,
                          pricePerUnit: product.pricePerUnit,
                          deliveryAddress: addresses[_selectedAddressIndex].address,
                        );
                        setState(() => _isLoading = false);
                        if (mounted) context.pushReplacement('/order-confirmation/$orderId');
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
