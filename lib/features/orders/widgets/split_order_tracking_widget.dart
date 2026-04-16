import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';

class SplitOrderTrackingWidget extends StatefulWidget {
  final OrderModel order;
  const SplitOrderTrackingWidget({super.key, required this.order});

  @override
  State<SplitOrderTrackingWidget> createState() =>
      _SplitOrderTrackingWidgetState();
}

class _SplitOrderTrackingWidgetState extends State<SplitOrderTrackingWidget> {
  Map<String, Map<String, dynamic>> _splitTrackingMap = {};
  StreamSubscription? _partsSubscription;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initPartsListener();
  }

  void _initPartsListener() {
    _partsSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.order.id)
        .collection('orderParts')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        final Map<String, Map<String, dynamic>> newMap = {};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final steps = data['trackingSteps'] as List?;

          if (steps != null) {
            newMap[doc.id] = {
              'vendorId': data['vendorId'] ?? '',
              'vendorName': data['vendorName'] ?? '',
              'quantity': data['quantity'] ?? 0,
              'unit': data['unit'] ?? 'units',
              'status': data['status'] ?? '',
              'trackingNumber': data['trackingNumber'],
              'steps': steps.map((s) => Map<String, dynamic>.from(s)).toList(),
            };
          }
        }
        setState(() {
          _splitTrackingMap = newMap;
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
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
    const primaryColor = Color(0xFF0D5C2F);

    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: primaryColor));
    }

    final totalParts = _splitTrackingMap.length;
    final deliveredCount = _splitTrackingMap.values
        .where((p) => p['status'] == 'delivered')
        .length;
    final progress = totalParts > 0 ? deliveredCount / totalParts : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header Card
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.divider),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Number',
                            style: TextStyle(
                                color: AppColors.textMedium, fontSize: 12),
                          ),
                          Text(
                            widget.order.orderNumber,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      _buildStatusBadge(widget.order.status, primaryColor),
                    ],
                  ),
                  const Divider(height: 24),
                  if (widget.order.customerPrice > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Paid',
                            style: TextStyle(fontSize: 14)),
                        Text(
                          formatPKR(widget.order.customerPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Overall Progress Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$deliveredCount of $totalParts shipments delivered',
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.divider,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(primaryColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Shipments by Vendor',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),

          // Per-vendor sections
          ..._splitTrackingMap.entries.map((entry) {
            final partData = entry.value;
            final steps = partData['steps'] as List;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vendor header
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.store, color: primaryColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Vendor: ${partData['vendorName'] ?? "Vendor"}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${partData['quantity']} ${partData['unit']}',
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ]),
                ),
                // Timeline steps for this vendor
                ...steps.map((step) => _buildTrackingStep(
                    context,
                    step,
                    steps.indexOf(step),
                    steps.length,
                    partData['trackingNumber'])),
                const SizedBox(height: 16),
              ],
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTrackingStep(BuildContext context, Map<String, dynamic> step,
      int index, int totalSteps, String? trackingNumber) {
    final isCompleted = step['status'] == 'completed';
    final isInProgress = step['status'] == 'in-progress';
    const primaryColor = Color(0xFF0D5C2F);

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
                  ? primaryColor
                  : Theme.of(context).cardColor,
              border: Border.all(
                color: isCompleted || isInProgress
                    ? primaryColor
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
          if (index < totalSteps - 1)
            Container(
              width: 2,
              height: 60,
              color: isCompleted ? primaryColor : AppColors.divider,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          ? primaryColor
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
                        'Tracking No: ${trackingNumber ?? "N/A"}',
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
                      context, List<String>.from(step['images'] as List)),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildStatusBadge(String status, Color primary) {
    String label = status.replaceAll('-', ' ').toUpperCase();
    Color bgColor = primary.withOpacity(0.1);
    Color textColor = primary;

    if (status == 'completed') {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
