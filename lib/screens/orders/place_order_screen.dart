import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/order_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/product.dart';
import '../../widgets/common/hunarmand_button.dart';
import '../../widgets/common/cached_image.dart';
import '../../models/user.dart';

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
  late Future<DocumentSnapshot> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .get();
  }

  @override
  void dispose() {
    _specialInstructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = context.read<VendorProvider>();
    final userProvider = context.watch<UserProvider>();
    final addresses = userProvider.addresses;

    return FutureBuilder<DocumentSnapshot>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')));
        }

        final doc = snapshot.data;
        if (doc == null || !doc.exists) {
          return const Scaffold(body: Center(child: Text('Product not found')));
        }

        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        final product = Product.fromMap(data, doc.id);
        final vendor = vendorProvider.getById(product.vendorId);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
              title: const Text('Place Order'),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              elevation: 0),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product summary
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AppCachedImage(
                            url: product.images.first, width: 72, height: 72),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.title,
                                style: AppTypography.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2),
                            Text('by ${vendor?.name ?? 'Loading...'}',
                                style: AppTypography.small
                                    .copyWith(color: AppColors.textMedium)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Delivery Address
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 20, color: AppColors.primaryGreen),
                              const SizedBox(width: 8),
                              Text('Delivery Address',
                                  style: AppTypography.bodyMedium
                                      .copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          TextButton(
                            onPressed: () =>
                                _showAddAddressBottomSheet(context),
                            child: const Text('+ Add New',
                                style:
                                    TextStyle(color: AppColors.primaryGreen)),
                          ),
                        ],
                      ),
                      if (addresses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                              child:
                                  Text('No addresses found. Please add one.')),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: addresses.length,
                          itemBuilder: (ctx, i) {
                            final isSelected = _selectedAddressIndex == i;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedAddressIndex = i),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryGreen
                                          : AppColors.divider),
                                  borderRadius: BorderRadius.circular(10),
                                  color: isSelected
                                      ? AppColors.primaryGreen.withAlpha(10)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      size: 20,
                                      color: isSelected
                                          ? AppColors.primaryGreen
                                          : AppColors.textLight,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(addresses[i].label,
                                              style: AppTypography.small
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                          Text(addresses[i].address,
                                              style: AppTypography.caption,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),

                // Order Details
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Details',
                          style: AppTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quantity'),
                          Row(
                            children: [
                              _QtyBtn(
                                  icon: Icons.remove,
                                  onTap: _quantity > 1
                                      ? () => setState(() => _quantity--)
                                      : null),
                              SizedBox(
                                  width: 40,
                                  child: Text(_quantity.toString(),
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold))),
                              _QtyBtn(
                                  icon: Icons.add,
                                  onTap: () => setState(() => _quantity++)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Options
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      _OptionTile(
                        icon: Icons.call_outlined,
                        title: 'Call before delivery',
                        value: _callBeforeDelivery,
                        onChanged: (v) =>
                            setState(() => _callBeforeDelivery = v),
                      ),
                      _OptionTile(
                        icon: Icons.door_front_door_outlined,
                        title: 'Leave at gate',
                        value: _leaveAtGate,
                        onChanged: (v) => setState(() => _leaveAtGate = v),
                      ),
                    ],
                  ),
                ),

                // Terms
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _termsAccepted,
                          onChanged: (v) =>
                              setState(() => _termsAccepted = v ?? false),
                          activeColor: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'I agree to the Terms & Conditions and Shipping Policy.',
                          style: AppTypography.caption,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Space for bottom bar
              ],
            ),
          ),
          bottomSheet: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, -5))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: HunarmandButton(
                    label: _isLoading ? 'Placing Order...' : 'Place My Order',
                    isLoading: _isLoading,
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (addresses.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please add a delivery address first.'),
                                    backgroundColor: AppColors.statusCancelled),
                              );
                              return;
                            }
                            if (_quantity < product.moq) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Minimum order quantity for this item is ${product.moq} units.'),
                                  backgroundColor: AppColors.statusCancelled,
                                ),
                              );
                              return;
                            }
                            if (!_termsAccepted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please agree to the Terms & Conditions to proceed.'),
                                  backgroundColor: AppColors.statusCancelled,
                                ),
                              );
                              return;
                            }

                            setState(() => _isLoading = true);
                            try {
                              final selectedAddress =
                                  addresses[_selectedAddressIndex].address;

                              final orderId = await context
                                  .read<OrderProvider>()
                                  .placeOrder(
                                    productId: product.id,
                                    quantity: _quantity,
                                    deliveryAddress: selectedAddress,
                                  );

                              print('Order created successfully: $orderId');

                              if (!context.mounted) return;
                              setState(() => _isLoading = false);
                              context.pushReplacement(
                                  '/order-confirmation/$orderId');
                            } catch (e) {
                              print('Order creation error: $e');
                              if (!context.mounted) return;
                              setState(() => _isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Failed to place order: $e')),
                              );
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddAddressBottomSheet(BuildContext context) {
    final addressCtrl = TextEditingController();
    String selectedLabel = 'Home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add New Address', style: AppTypography.h3),
                  IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              Text('Label',
                  style: AppTypography.small
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: ['Home', 'Work', 'Other'].map((label) {
                  final isSelected = selectedLabel == label;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedLabel = label),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(label,
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textMedium)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Full Address',
                  style: AppTypography.small
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: addressCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Enter your detail address...'),
              ),
              const SizedBox(height: 24),
              HunarmandButton(
                label: 'Save Address',
                onPressed: () async {
                  if (addressCtrl.text.isEmpty) return;

                  final newAddr = UserAddress(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    label: selectedLabel,
                    address: addressCtrl.text,
                    isDefault: false,
                  );

                  await context.read<UserProvider>().addAddress(newAddr);

                  if (!context.mounted) return;
                  Navigator.pop(ctx);

                  // Select the newly added address (it's last in the list)
                  setState(() => _selectedAddressIndex =
                      context.read<UserProvider>().addresses.length - 1);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(
              color:
                  onTap != null ? AppColors.primaryGreen : AppColors.divider),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 20,
            color:
                onTap != null ? AppColors.primaryGreen : AppColors.textLight),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final Function(bool) onChanged;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMedium),
          const SizedBox(width: 12),
          Text(title, style: AppTypography.body),
        ],
      ),
      activeThumbColor: AppColors.primaryGreen,
      contentPadding: EdgeInsets.zero,
    );
  }
}
