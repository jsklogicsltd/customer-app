import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/order.dart';

class SplitOrderTrackingScreen extends StatelessWidget {
  final String splitOrderId;
  const SplitOrderTrackingScreen({super.key, required this.splitOrderId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').doc(splitOrderId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)));
        }

        final doc = snapshot.data!;
        if (!doc.exists) {
          return const Scaffold(body: Center(child: Text('Split order not found')));
        }

        final splitOrder = OrderModel.fromFirestore(doc);

        return Scaffold(
          backgroundColor: AppColors.bgLight,
          appBar: AppBar(
            title: Text(splitOrder.orderNumber.isNotEmpty ? splitOrder.orderNumber : splitOrder.id, style: AppTypography.h3),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(splitOrder),
                const SizedBox(height: 24),
                Text('Vendor Progress Tracking', style: AppTypography.h3),
                const SizedBox(height: 16),
                ...splitOrder.subOrders.map((subId) => _buildSubOrderCard(subId)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(OrderModel splitOrder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Split Order Active', style: AppTypography.h3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primaryGreen.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                child: const Text('ACTIVE', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(splitOrder.description, style: AppTypography.bodyMedium),
          const SizedBox(height: 8),
          Text('Monitoring real-time production and delivery across ${splitOrder.subOrders.length} vendors.', style: AppTypography.small.copyWith(color: AppColors.textMedium)),
        ],
      ),
    );
  }

  Widget _buildSubOrderCard(String subOrderId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('subOrders').doc(subOrderId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final doc = snapshot.data!;
        if (!doc.exists) return const SizedBox.shrink();
        
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status']?.toString() ?? 'unknown';
        final qty = data['assignedQuantity'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4)],
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sub-order', style: AppTypography.small.copyWith(color: AppColors.textMedium)),
                        Text('$qty units', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _SubOrderTimelineList(data: data),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'active' || status == 'in-production' || status == 'in_production') {
      color = AppColors.gold;
    } else if (status == 'dispatched') color = Colors.blue;
    else if (status == 'delivered') color = AppColors.primaryGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase().replaceAll('_', ' ').replaceAll('-', ' '), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _SubOrderTimelineList extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SubOrderTimelineList({required this.data});

  @override
  Widget build(BuildContext context) {
    final rawSteps = data['trackingSteps'] as List<dynamic>? ?? [];
    final steps = List<Map<String, dynamic>>.from(rawSteps);
    
    if (steps.isEmpty) {
      return const Text("No tracking steps yet.", style: TextStyle(color: Colors.grey, fontSize: 12));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final step = steps[index];
        final title = step['title']?.toString() ?? 'Step';
        final desc = step['description']?.toString() ?? '';
        final status = step['status']?.toString().toLowerCase() ?? 'pending';

        DateTime? completedDate;
        if (step['completedDate'] != null) completedDate = (step['completedDate'] as Timestamp).toDate();

        Widget icon;
        if (status == 'completed') {
          icon = const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20);
        } else if (status == 'in_progress' || status == 'in-progress') icon = const Icon(Icons.radio_button_checked, color: AppColors.gold, size: 20);
        else icon = const Icon(Icons.radio_button_off, color: Colors.grey, size: 20);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                    if (status == 'completed' && completedDate != null) ...[
                      const SizedBox(height: 4),
                      Text(DateFormat('d MMM yyyy, h:mm a').format(completedDate), style: const TextStyle(color: Colors.black54, fontSize: 11)),
                    ],
                    // Vendor-uploaded photos for this step
                    if (status == 'completed' && step['images'] != null && (step['images'] as List).isNotEmpty)
                      _buildImagesRow(context, List<String>.from(step['images'] as List)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagesRow(BuildContext context, List<String> urls) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: urls.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) => GestureDetector(
            onTap: () => _openFullscreen(context, urls[i]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: urls[i],
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 72, height: 72,
                  color: const Color(0xFFF4F4F4),
                  child: const Center(
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 72, height: 72,
                  color: const Color(0xFFF4F4F4),
                  child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context, String imageUrl) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
              errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 64),
            ),
          ),
        ),
      ),
    ));
  }
}
