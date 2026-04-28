import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../models/quote.dart';
import '../../providers/order_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/cached_image.dart';

class QuoteDetailScreen extends StatefulWidget {
  final QuoteModel? quote;
  final OrderModel? order;
  final bool isSplitOrder;

  const QuoteDetailScreen({
    super.key,
    this.quote,
    this.order,
    this.isSplitOrder = false,
  });

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  Map<String, dynamic>? _extraDetails;
  bool _isLoadingDetails = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchExtraDetails();
  }

  Future<void> _fetchExtraDetails() async {
    try {
      final db = FirebaseFirestore.instance;
      String? productId;
      String orderId = widget.order?.id ?? widget.quote?.orderId ?? '';

      Map<String, dynamic> mergedDetails = {};

      if (orderId.isNotEmpty) {
        final orderDoc = await db.collection('orders').doc(orderId).get();
        if (orderDoc.exists) {
          final data = orderDoc.data()!;
          productId = data['productId'];
          mergedDetails.addAll(data);
        }
      }

      if (productId != null && productId.isNotEmpty) {
        final productDoc = await db.collection('products').doc(productId).get();
        if (productDoc.exists) {
          mergedDetails.addAll(productDoc.data()!);
        }
      }

      // Check custom requests if any match this orderId or product name
      final productName = widget.order?.productName ?? widget.quote?.productName ?? '';
      final user = context.read<UserProvider>().user;
      if (user != null) {
        final reqQuery = await db.collection('customRequests')
            .where('customerId', isEqualTo: user.id)
            .get();
        
        for (var doc in reqQuery.docs) {
           final data = doc.data();
           if (data['confirmedOrderId'] == orderId || 
               doc.id == orderId || 
               doc.id == productId || 
               (productName.isNotEmpty && data['productName'] == productName) ||
               (productName.isNotEmpty && data['productType'] == productName)) {
               mergedDetails.addAll(data);
               break;
           }
        }
      }

      if (mounted) {
        setState(() {
          _extraDetails = mergedDetails;
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching extra details: $e');
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  int _getValidQuantity() {
    int parsedQ = widget.order?.quantity ?? widget.quote?.quantity ?? 0;
    if (parsedQ > 0) return parsedQ;

    if (_extraDetails != null) {
      final keys = ['quantity', 'qty', 'totalQuantity', 'step1Quantity'];
      for (var key in keys) {
        final val = _extraDetails![key];
        if (val != null) {
          if (val is int && val > 0) return val;
          if (val is num && val > 0) return val.toInt();
          if (val is String) {
            final tryQ = int.tryParse(val);
            if (tryQ != null && tryQ > 0) return tryQ;
          }
        }
      }
    }
    return 1; // Absolute fallback
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.order?.mainPhotoUrl ?? widget.quote?.productPhoto ?? _extraDetails?['mainPhotoUrl'] ?? '';
    String productName = widget.order?.productName ?? widget.quote?.productName ?? '';
    if (productName.isEmpty || productName == 'Custom Request Quote') {
      final extraName = _extraDetails?['productName'];
      final extraType = _extraDetails?['productType'];
      if (extraName != null && extraName.toString().isNotEmpty) {
        productName = extraName.toString();
      } else if (extraType != null && extraType.toString().isNotEmpty) {
        productName = extraType.toString();
      } else {
        productName = 'Custom Request Quote';
      }
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(photoUrl, productName),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderInfo(productName),
                      if (widget.quote?.createdAt != null || widget.order?.createdAt != null || _extraDetails?['createdAt'] != null) ...[
                        const SizedBox(height: 12),
                        _buildDateRow(),
                      ],
                      const SizedBox(height: 20),
                      if (_isLoadingDetails)
                        const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                      else
                        _buildProductSpecifications(),
                      const SizedBox(height: 20),
                      _buildPricingSection(context),
                      if (widget.quote?.notes != null && widget.quote!.notes.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildNotesSection(),
                      ],
                      const SizedBox(height: 100), // Padding for bottom buttons
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(String photoUrl, String productName) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.primaryGreen,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Quote Details',
          style: AppTypography.h3.copyWith(color: Colors.white, shadows: [
            Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)
          ]),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            photoUrl.isNotEmpty
                ? AppCachedImage(url: photoUrl, fit: BoxFit.cover)
                : Container(
                    color: AppColors.primaryGreen.withOpacity(0.8),
                    child: const Icon(Icons.receipt_long, size: 80, color: Colors.white),
                  ),
            // Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(String productName) {
    final int qty = _getValidQuantity();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  productName,
                  style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold, height: 1.2),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Qty: $qty',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.textMedium),
              const SizedBox(width: 6),
              Text(
                'Order Quote Information',
                style: AppTypography.small.copyWith(color: AppColors.textMedium),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow() {
    dynamic createdAt = widget.quote?.createdAt ?? widget.order?.createdAt ?? _extraDetails?['createdAt'];
    String formattedDate = 'Date not available';
    if (createdAt != null) {
      if (createdAt is Timestamp) {
        formattedDate = formatDate(createdAt.toDate());
      } else if (createdAt is String) {
        formattedDate = createdAt;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Text(
                'Quote Date',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMedium),
              ),
            ],
          ),
          Text(
            formattedDate,
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSpecifications() {
    final category = _extraDetails?['category'] as String?;
    final subCategory = _extraDetails?['subCategory'] as String?;
    final color = _extraDetails?['color'] as String?;
    final material = _extraDetails?['material'] as String?;
    final sizes = _extraDetails?['sizes'] as List<dynamic>?;
    final deadline = widget.quote?.productionDays?.toString() ?? _extraDetails?['deadline'] ?? _extraDetails?['productionDays']?.toString();

    bool hasSpecs = category != null || subCategory != null || color != null || material != null || (sizes != null && sizes.isNotEmpty);

    if (!hasSpecs) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Specifications',
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (category != null && category.isNotEmpty) _buildSpecRow(Icons.category_outlined, 'Category', category),
              if (subCategory != null && subCategory.isNotEmpty) _buildSpecRow(Icons.account_tree_outlined, 'Sub-Category', subCategory),
              if (color != null && color.isNotEmpty) _buildSpecRow(Icons.color_lens_outlined, 'Color', color),
              if (material != null && material.isNotEmpty) _buildSpecRow(Icons.texture_outlined, 'Material', material),
              if (sizes != null && sizes.isNotEmpty) _buildSpecRow(Icons.straighten_outlined, 'Sizes', sizes.join(', ')),
              if (deadline != null && deadline.toString().isNotEmpty) _buildSpecRow(Icons.timer_outlined, 'Timeline / Deadline', '$deadline Days'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMedium),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(BuildContext context) {
    final role = context.watch<UserProvider>().user?.role ?? 'customer';
    final isAdmin = role == 'admin';

    num finalPrice = 0;
    num unitPrice = 0;
    final int qty = _getValidQuantity();

    if (widget.quote != null) {
      finalPrice = widget.quote!.customerFinalPrice > 0 ? widget.quote!.customerFinalPrice : widget.quote!.totalPrice;
      unitPrice = isAdmin ? widget.quote!.unitPrice : (qty > 0 ? (finalPrice / qty) : widget.quote!.unitPrice);
    } else if (widget.order != null) {
      if (widget.isSplitOrder) {
        finalPrice = widget.order!.splitCustomerFinalPrice > 0 ? widget.order!.splitCustomerFinalPrice : widget.order!.customerPrice;
        unitPrice = qty > 0 ? (finalPrice / qty) : widget.order!.unitPrice;
      } else {
        finalPrice = widget.order!.customerPrice;
        unitPrice = qty > 0 ? (finalPrice / qty) : widget.order!.vendorQuote;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing Details',
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Price per Unit', style: AppTypography.bodyMedium.copyWith(color: AppColors.textDark)),
                  Text(formatPKR(unitPrice), style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quantity', style: AppTypography.bodyMedium.copyWith(color: AppColors.textDark)),
                  Text('x $qty', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.black12, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Final Price',
                    style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  Text(
                    formatPKR(finalPrice),
                    style: AppTypography.h2.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w900,
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
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vendor Notes',
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.note_alt_outlined, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.quote!.notes,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: _isActionLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
              : Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () => _handleDecline(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => _handleAccept(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Accept Quote', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context) async {
    setState(() => _isActionLoading = true);
    try {
      final user = context.read<UserProvider>().user;
      
      if (widget.quote != null) {
        final finalPrice = widget.quote!.customerFinalPrice > 0 ? widget.quote!.customerFinalPrice : widget.quote!.totalPrice;
        await context.read<QuoteProvider>().acceptQuote(
          widget.quote!.id,
          widget.quote!.orderId,
          finalPrice,
          customerName: user?.name,
        );
      } else if (widget.order != null) {
        if (widget.isSplitOrder) {
          await context.read<OrderProvider>().acceptSplitQuote(
            widget.order!.id,
            customerName: user?.name,
          );
        } else {
          await context.read<OrderProvider>().acceptNormalQuote(
            widget.order!.id,
            customerName: user?.name,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote Accepted! Your order is now in production.'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        // Ensure active tab is selected
        context.read<OrderProvider>().ordersTabIndex = 3;
        context.pop(); // Go back to orders list
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Quote?'),
        content: const Text('Are you sure? The order will be cancelled and cannot be undone.'),
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
      final user = context.read<UserProvider>().user;
      
      if (widget.quote != null) {
        await context.read<QuoteProvider>().declineQuote(
          widget.quote!.id, 
          widget.quote!.orderId,
          customerName: user?.name,
        );
      } else if (widget.order != null) {
        if (widget.isSplitOrder) {
           await context.read<OrderProvider>().declineSplitQuote(
             widget.order!.id,
             customerName: user?.name,
           );
        } else {
           await context.read<OrderProvider>().declineNormalQuote(
             widget.order!.id,
             customerName: user?.name,
           );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote Declined. Order cancelled.'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop(); // Go back to orders list
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
