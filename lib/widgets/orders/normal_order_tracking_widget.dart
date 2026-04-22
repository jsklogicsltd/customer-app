import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';

class NormalOrderTrackingWidget extends StatefulWidget {
  final OrderModel order;
  const NormalOrderTrackingWidget({super.key, required this.order});

  @override
  State<NormalOrderTrackingWidget> createState() =>
      _NormalOrderTrackingWidgetState();
}

class _NormalOrderTrackingWidgetState extends State<NormalOrderTrackingWidget> {
  List<Map<String, dynamic>> _trackingSteps = [];
  String? _trackingNumber;
  StreamSubscription? _orderSubscription;
  StreamSubscription? _partsSubscription;

  @override
  void initState() {
    super.initState();
    _initTrackingListener();
  }

  void _initTrackingListener() {
    // 1. Listen to the main order doc for basic info
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.order.id)
        .snapshots()
        .listen((doc) {
      debugPrint(
          '=== [Tracking] Root order doc exists: ${doc.exists}, id: ${widget.order.id}');
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('=== [Tracking] Root doc ALL fields: ${data.keys.toList()}');
        debugPrint(
            '=== [Tracking] trackingSteps field: ${data["trackingSteps"]}');
        debugPrint('=== [Tracking] status: ${data["status"]}');
        final steps = data['trackingSteps'] as List?;
        setState(() {
          if (steps != null && steps.isNotEmpty) {
            _trackingSteps =
                steps.map((s) => Map<String, dynamic>.from(s)).toList();
          }
          if (data['trackingNumber'] != null) {
            _trackingNumber = data['trackingNumber'];
          }
        });
      }
    });

    // 2. Listen to orderParts subcollection (where vendors usually update tracking)
    _partsSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.order.id)
        .collection('orderParts')
        .snapshots()
        .listen((snapshot) {
      debugPrint(
          '=== [Tracking] orderParts snapshot: ${snapshot.docs.length} docs found');
      if (snapshot.docs.isNotEmpty) {
        for (final doc in snapshot.docs) {
          debugPrint(
              '=== [Tracking] partDoc id: ${doc.id}, fields: ${doc.data().keys.toList()}');
          debugPrint(
              '=== [Tracking] partDoc trackingSteps: ${doc.data()["trackingSteps"]}');
          debugPrint('=== [Tracking] partDoc status: ${doc.data()["status"]}');
        }
      }
      if (mounted && snapshot.docs.isNotEmpty) {
        final partData = snapshot.docs.first.data();
        final steps = partData['trackingSteps'] as List?;
        final tNum = partData['trackingNumber'] as String?;
        debugPrint('=== [Tracking] Using part trackingSteps: $steps');

        setState(() {
          if (_trackingSteps.isEmpty && steps != null) {
            _trackingSteps =
                steps.map((s) => Map<String, dynamic>.from(s)).toList();
          }
          if (_trackingNumber == null && tNum != null) {
            _trackingNumber = tNum;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _partsSubscription?.cancel();
    super.dispose();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day} ${_monthName(date.month)}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressCard(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Project Timeline', style: AppTypography.h3),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTimeline(),
          ),
          _buildOrderDetailsCard(widget.order),
          _buildVendorCard(widget.order),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    if (_trackingSteps.isEmpty) return const SizedBox.shrink();

    final currentIdx = () {
      final idx =
          _trackingSteps.indexWhere((s) => s['status'] == 'in-progress');
      if (idx != -1) return idx;
      if (_trackingSteps.every((s) => s['status'] == 'completed')) {
        return _trackingSteps.length;
      }
      return 0;
    }();

    final progress = ((currentIdx) /
            (_trackingSteps.length > 1 ? _trackingSteps.length - 1 : 1) *
            100)
        .clamp(0, 100)
        .toInt();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: progress / 100,
                  strokeWidth: 10,
                  backgroundColor: AppColors.divider,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF0D5C2F)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$progress%',
                    style: AppTypography.h1.copyWith(fontSize: 28),
                  ),
                  Text(
                    'Complete',
                    style: AppTypography.small
                        .copyWith(color: AppColors.textMedium),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getCurrentStatusText(),
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Live updates from vendor',
            style: AppTypography.small.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  String _getCurrentStatusText() {
    if (_trackingSteps.isEmpty) {
      return widget.order.status.replaceAll('-', ' ').toUpperCase();
    }
    final inProgress =
        _trackingSteps.where((s) => s['status'] == 'in-progress');
    if (inProgress.isNotEmpty) return inProgress.first['title'] ?? '';

    final lastCompleted = _trackingSteps.lastWhere(
        (s) => s['status'] == 'completed',
        orElse: () => _trackingSteps.first);
    return lastCompleted['title'] ?? '';
  }

  Widget _buildTimeline() {
    if (_trackingSteps.isEmpty) {
      final activeStatuses = ['active', 'in-production', 'customer-confirmed', 'ready-to-ship'];
      if (activeStatuses.contains(widget.order.status.toLowerCase())) {
        // Return a virtual "Order Accepted" step if it's active but no steps are in DB yet
        return _buildVirtualStep(
          title: "Order Accepted",
          description: "Your order has been accepted and is being prepared by the vendor.",
          status: "completed",
        );
      }
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text("No tracking steps yet.", style: TextStyle(color: AppColors.textMedium)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _trackingSteps.length,
      itemBuilder: (context, index) {
        final step = _trackingSteps[index];
        final isCompleted = step['status'] == 'completed';
        final isInProgress = step['status'] == 'in-progress';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circle indicator
            Column(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted || isInProgress
                      ? const Color(0xFF0D5C2F)
                      : Theme.of(context).cardColor,
                  border: Border.all(
                    color: isCompleted || isInProgress
                        ? const Color(0xFF0D5C2F)
                        : AppColors.divider,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check
                      : isInProgress
                          ? Icons.play_arrow
                          : null,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              // Connector line
              if (index < _trackingSteps.length - 1)
                Container(
                  width: 2,
                  height: 60,
                  color:
                      isCompleted ? const Color(0xFF0D5C2F) : AppColors.divider,
                ),
            ]),

            const SizedBox(width: 12),

            // Step card
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            step['title'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Text(
                          isCompleted
                              ? _formatDate(step['completedAt'])
                              : 'Expected: ${_formatDate(step['expectedDate'])}',
                          style: const TextStyle(
                              color: AppColors.textLight, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step['description'] ?? '',
                      style: const TextStyle(
                          color: AppColors.textMedium, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFFE8F5EE).withAlpha(40)
                            : isInProgress
                                ? const Color(0xFFFFF5D6).withAlpha(40)
                                : AppColors.divider.withAlpha(40),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        isCompleted
                            ? '✓ Completed'
                            : isInProgress
                                ? '● In Progress'
                                : '○ Pending',
                        style: TextStyle(
                          color: isCompleted
                              ? const Color(0xFF0D5C2F)
                              : isInProgress
                                  ? const Color(0xFF8A6000)
                                  : AppColors.textMedium,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Show tracking number in dispatched step
                    if (step['stepId'] == 'dispatched' && isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(children: [
                          const Icon(Icons.local_shipping,
                              size: 14, color: AppColors.textMedium),
                          const SizedBox(width: 4),
                          Text(
                            'Tracking No: ${_trackingNumber ?? "N/A"}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMedium),
                          ),
                        ]),
                      ),
                    // Vendor-uploaded photos for this step
                    if (isCompleted &&
                        step['images'] != null &&
                        (step['images'] as List).isNotEmpty)
                      _buildImagesRow(
                          List<String>.from(step['images'] as List)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImagesRow(List<String> urls) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: urls.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) => GestureDetector(
            onTap: () => _openFullscreen(urls[i]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: urls[i],
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 72,
                  height: 72,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: const Center(
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 72,
                  height: 72,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppColors.textLight),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullscreen(String imageUrl) {
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
              placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.white, size: 64),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildOrderDetailsCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildDetailRow(
              Icons.inventory_2_outlined, 'Product:', order.productName),
          _buildDetailRow(
              Icons.numbers, 'Quantity:', '${order.quantity} units'),
          _buildDetailRow(Icons.label_outline, 'Category:', 'Handicrafts'),
          if (order.confirmedPrice > 0 || order.totalAmount > 0)
            _buildDetailRow(
                Icons.payments_outlined,
                'Order Value:',
                formatPKR(order.confirmedPrice > 0
                    ? order.confirmedPrice
                    : order.totalAmount)),
          _buildDetailRow(Icons.calendar_today_outlined, 'Delivery Date:',
              order.expectedDelivery),
          _buildDetailRow(Icons.location_on_outlined, 'Delivery Location:',
              order.deliveryAddress),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMedium),
          const SizedBox(width: 12),
          SizedBox(
              width: 100,
              child: Text(label,
                  style: AppTypography.small
                      .copyWith(color: AppColors.textMedium))),
          Expanded(
              child: Text(value,
                  style: AppTypography.small
                      .copyWith(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildVendorCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Need Help?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.goldLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withAlpha(80),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'K',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Karsaazi Support',
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.bold)),
                    Text('Always here for you',
                        style: AppTypography.small
                            .copyWith(color: AppColors.textMedium)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.push(
                  '/chat/order/${order.id}',
                  extra: {
                    'orderId': order.id,
                    'orderNumber': order.orderNumber.isNotEmpty
                        ? order.orderNumber
                        : order.id,
                    'threadId':
                        '${order.id}_CUSTOMER_${order.customerId}',
                  },
                );
              },
              icon: const Icon(Icons.support_agent_rounded, size: 18),
              label: const Text('Contact Support'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.gold),
                foregroundColor: AppColors.gold,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualStep({
    required String title,
    required String description,
    required String status,
  }) {
    final isCompleted = status == 'completed';
    final isInProgress = status == 'in-progress';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted || isInProgress
                  ? const Color(0xFF0D5C2F)
                  : Theme.of(context).cardColor,
              border: Border.all(
                color: isCompleted || isInProgress
                    ? const Color(0xFF0D5C2F)
                    : AppColors.divider,
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted
                  ? Icons.check
                  : isInProgress
                      ? Icons.play_arrow
                      : null,
              color: Colors.white,
              size: 16,
            ),
          ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFFE8F5EE).withAlpha(40)
                        : isInProgress
                            ? const Color(0xFFFFF5D6).withAlpha(40)
                            : AppColors.divider.withAlpha(40),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    isCompleted
                        ? '✓ Completed'
                        : isInProgress
                            ? '● In Progress'
                            : '○ Pending',
                    style: TextStyle(
                      color: isCompleted
                          ? const Color(0xFF0D5C2F)
                          : isInProgress
                              ? const Color(0xFF8A6000)
                              : AppColors.textMedium,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
