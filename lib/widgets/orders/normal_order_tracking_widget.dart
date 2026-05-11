import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../models/chat_message.dart';

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
  Map<String, dynamic>? _extraDetails;

  @override
  void initState() {
    super.initState();
    _initTrackingListener();
    _fetchExtraDetails();
  }

  void _fetchExtraDetails() async {
    try {
      Map<String, dynamic> merged = {};
      
      final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(widget.order.id).get();
      if (orderDoc.exists) {
        merged.addAll(orderDoc.data() as Map<String, dynamic>);
      }

      final productId = widget.order.productId;
      if (productId.isNotEmpty) {
        final prodDoc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
        if (prodDoc.exists) {
          merged.addAll(prodDoc.data() as Map<String, dynamic>);
        }
      }

      final customerId = widget.order.customerId;
      if (customerId.isNotEmpty) {
        final reqs = await FirebaseFirestore.instance
            .collection('customRequests')
            .where('customerId', isEqualTo: customerId)
            .get();
        
        for (var doc in reqs.docs) {
          final data = doc.data();
          if (data['confirmedOrderId'] == widget.order.id || 
              doc.id == widget.order.id || 
              doc.id == productId || 
              (widget.order.productName.isNotEmpty && data['productName'] == widget.order.productName) ||
              (widget.order.productName.isNotEmpty && data['productType'] == widget.order.productName) ||
              (widget.order.productName.isNotEmpty && data['step1ProductName'] == widget.order.productName)) {
            merged.addAll(data);
            break;
          }
        }
      }

      // 4. Also fetch quote details if possible to get lead time/delivery info
      if (widget.order.quoteId.isNotEmpty) {
        final quoteDoc = await FirebaseFirestore.instance.collection('quotes').doc(widget.order.quoteId).get();
        if (quoteDoc.exists) {
          final quoteData = quoteDoc.data()!;
          merged['promisedTimeline'] = quoteData['timeline'];
          if (quoteData['expectedDelivery'] != null) {
            merged['expectedDelivery'] = quoteData['expectedDelivery'];
          }
        }
      }

      if (mounted) {
        setState(() {
          _extraDetails = merged;
        });
      }
    } catch (e) {
      debugPrint('Error fetching extra details: $e');
    }
  }

  int _getValidQuantity() {
    int parsedQ = widget.order.quantity;
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
    return 1;
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
        var steps = data['trackingSteps'] as List?;
        
        // Fallback to 'timeline' if trackingSteps is missing
        if (steps == null || steps.isEmpty) {
          final timelineRaw = data['timeline'] as List?;
          if (timelineRaw != null && timelineRaw.isNotEmpty) {
            steps = timelineRaw.map((t) => {
              'stepId': t['step'] ?? '',
              'title': t['step'] ?? '',
              'description': t['note'] ?? '',
              'status': (t['completed'] == true || t['completed'] == 1) ? 'completed' : 'pending',
              'completedAt': t['date'],
              'expectedDate': t['date'],
            }).toList();
          }
        }

        setState(() {
          if (steps != null && steps.isNotEmpty) {
            _trackingSteps =
                steps.map((s) => Map<String, dynamic>.from(s as Map)).toList();
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
        var steps = partData['trackingSteps'] as List?;
        
        // Fallback to 'timeline' if trackingSteps is missing
        if (steps == null || steps.isEmpty) {
          final timelineRaw = partData['timeline'] as List?;
          if (timelineRaw != null && timelineRaw.isNotEmpty) {
            steps = timelineRaw.map((t) => {
              'stepId': t['step'] ?? '',
              'title': t['step'] ?? '',
              'description': t['note'] ?? '',
              'status': (t['completed'] == true || t['completed'] == 1) ? 'completed' : 'pending',
              'completedAt': t['date'],
              'expectedDate': t['date'],
            }).toList();
          }
        }

        final tNum = partData['trackingNumber'] as String?;
        debugPrint('=== [Tracking] Using part trackingSteps: $steps');

        setState(() {
          if (_trackingSteps.isEmpty && steps != null) {
            _trackingSteps =
                steps.map((s) => Map<String, dynamic>.from(s as Map)).toList();
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
          _buildSupportCard(widget.order),
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

    int progress = 0;
    final normalizedStatus = widget.order.status.toLowerCase();
    if (normalizedStatus == 'completed' || normalizedStatus == 'delivered') {
      progress = 100;
    } else {
      for (var step in _trackingSteps) {
        if (step['status'] == 'completed') {
          final p = (step['percentage'] as num?)?.toInt() ?? 0;
          if (p > progress) progress = p;
        }
      }
      if (progress == 0) {
        progress = ((currentIdx) /
                (_trackingSteps.length > 1 ? _trackingSteps.length - 1 : 1) *
                100)
            .clamp(0, 100)
            .toInt();
      }
    }

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
            'Live updates on your project',
            style: AppTypography.small.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  String _getCurrentStatusText() {
    if (_trackingSteps.isEmpty) {
      return widget.order.status.toLowerCase().replaceAll('_', '-').replaceAll('-', ' ').toUpperCase();
    }
    
    // Check for rejected steps first (highest priority for customer visibility)
    final rejected = _trackingSteps.where((s) => s['status'] == 'rejected');
    if (rejected.isNotEmpty) return 'Action Required';

    // Check for review
    final underReview = _trackingSteps.where((s) => s['status'] == 'under_review');
    if (underReview.isNotEmpty) return 'Quality Check in Progress';

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
      final normalizedStatus = widget.order.status.toLowerCase().replaceAll('_', '-');
      final activeStatuses = ['active', 'in-production', 'customer-confirmed', 'ready-to-ship'];
      if (activeStatuses.contains(normalizedStatus)) {
        // Return a virtual "Order Accepted" step if it's active but no steps are in DB yet
        return _buildVirtualStep(
          title: "Order Accepted",
          description: "Your order has been accepted and is being prepared.",
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
        final isUnderReview = step['status'] == 'under_review';
        final isRejected = step['status'] == 'rejected';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circle indicator
            Column(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF0D5C2F)
                      : isUnderReview || isRejected
                          ? const Color(0xFFC9A93C)
                          : isInProgress
                              ? const Color(0xFF0D5C2F)
                              : Theme.of(context).cardColor,
                  border: Border.all(
                    color: isCompleted || isInProgress
                        ? const Color(0xFF0D5C2F)
                        : isUnderReview || isRejected
                            ? const Color(0xFFC9A93C)
                            : AppColors.divider,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check
                      : isUnderReview
                          ? Icons.hourglass_empty
                          : isRejected
                              ? Icons.priority_high
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
                  border: Border.all(color: isRejected ? Colors.red.withOpacity(0.3) : AppColors.divider),
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
                    if (isRejected && step['qcFeedback'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Status Update: ${step['qcFeedback']}",
                          style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    const SizedBox(height: 6),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFFE8F5EE).withAlpha(40)
                            : isUnderReview
                                ? const Color(0xFFFFF5D6).withAlpha(40)
                                : isRejected
                                    ? const Color(0xFFFFEBEE).withAlpha(40)
                                    : isInProgress
                                        ? const Color(0xFFFFF5D6).withAlpha(40)
                                        : AppColors.divider.withAlpha(40),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        isCompleted
                            ? '✓ Completed'
                            : isUnderReview
                                ? '⧖ Quality Check'
                                : isRejected
                                    ? '⚠ Correction in Progress'
                                    : isInProgress
                                        ? '● In Progress'
                                        : '○ Pending',
                        style: TextStyle(
                          color: isCompleted
                              ? const Color(0xFF0D5C2F)
                              : isUnderReview
                                  ? const Color(0xFF8A6000)
                                  : isRejected
                                      ? Colors.red
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
                    // Vendor-uploaded media for this step
                    if ((isCompleted || isUnderReview || isRejected) &&
                        (step['mediaUrls'] != null || step['images'] != null))
                      _buildMediaRow(
                          List<String>.from((step['mediaUrls'] ?? step['images']) as List)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMediaRow(List<String> urls) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: urls.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final url = urls[i];
            final isVideo = url.contains('.mp4') || url.contains('video_');
            
            return GestureDetector(
              onTap: () => _openFullscreen(url, isVideo: isVideo),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 72, height: 72,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (isVideo)
                        const Center(child: Icon(Icons.play_circle_fill, color: Color(0xFF0D5C2F), size: 32))
                      else
                        CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                          errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: AppColors.textLight),
                        ),
                      if (isVideo)
                        Positioned(
                          bottom: 4, right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                            child: const Text('VIDEO', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openFullscreen(String url, {bool isVideo = false}) {
    // Basic photo viewer logic. For video, one would ideally use a video player.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Center(
          child: isVideo 
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam, color: Colors.white, size: 64),
                  SizedBox(height: 16),
                  Text('Video content available in full view', style: TextStyle(color: Colors.white)),
                ],
              )
            : InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 64),
                ),
              ),
        ),
      ),
    ));
  }

  Widget _buildOrderDetailsCard(OrderModel order) {
    final int qty = _getValidQuantity();
    final String cat = _extraDetails?['category'] ?? _extraDetails?['step1Category'] ?? 'N/A';
    final String subCat = _extraDetails?['subCategory'] ?? _extraDetails?['step1SubCategory'] ?? 'N/A';
    final String color = _extraDetails?['color'] ?? _extraDetails?['step1Color'] ?? 'N/A';
    final String material = _extraDetails?['material'] ?? _extraDetails?['step1Material'] ?? 'N/A';
    
    String sizeStr = 'N/A';
    if (_extraDetails?['size'] != null && _extraDetails!['size'].toString().isNotEmpty) {
      sizeStr = _extraDetails!['size'].toString();
    } else if (_extraDetails?['step2Measurements'] != null) {
      final meas = _extraDetails!['step2Measurements'];
      if (meas is Map) {
        sizeStr = meas.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      }
    } else if (_extraDetails?['dimensions'] != null) {
      sizeStr = _extraDetails!['dimensions'].toString();
    }

    final String orderDate = _formatDate(order.createdAt);
    
    String deliveryDate = 'N/A';
    if (order.expectedDelivery.isNotEmpty) {
      deliveryDate = order.expectedDelivery;
    } else if (_extraDetails?['expectedDelivery'] != null) {
      deliveryDate = _extraDetails!['expectedDelivery'].toString();
    } else if (_extraDetails?['deliveryDate'] != null) {
      deliveryDate = _extraDetails!['deliveryDate'].toString();
    } else if (_extraDetails?['deadline'] != null) {
      deliveryDate = _extraDetails!['deadline'].toString();
    } else if (_extraDetails?['promisedTimeline'] != null) {
      // Calculate from timeline (lead time in days)
      final timelineVal = _extraDetails!['promisedTimeline'];
      int? days;
      if (timelineVal is num) days = timelineVal.toInt();
      else if (timelineVal is String) {
        // Try to extract number from string like "5 days"
        final match = RegExp(r'(\d+)').firstMatch(timelineVal);
        if (match != null) days = int.tryParse(match.group(1)!);
        else days = int.tryParse(timelineVal);
      }
      
      if (days != null) {
        DateTime createdDateTime;
        if (order.createdAt is Timestamp) {
          createdDateTime = (order.createdAt as Timestamp).toDate();
        } else if (order.createdAt is DateTime) {
          createdDateTime = order.createdAt;
        } else {
          createdDateTime = DateTime.now();
        }
        final date = createdDateTime.add(Duration(days: days));
        deliveryDate = '${date.day} ${_monthName(date.month)} ${date.year}';
      }
    }

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
          _buildDetailRow(Icons.inventory_2_outlined, 'Product:', () {
            String pName = order.productName;
            if (pName.isEmpty || pName.startsWith('Order #')) {
              if (_extraDetails != null) {
                pName = _extraDetails!['productName'] ?? _extraDetails!['step1ProductName'] ?? _extraDetails!['productType'] ?? pName;
              }
            }
            return pName;
          }()),
          _buildDetailRow(Icons.numbers, 'Quantity:', '$qty units'),
          if (cat != 'N/A') _buildDetailRow(Icons.category_outlined, 'Category:', cat),
          if (subCat != 'N/A') _buildDetailRow(Icons.account_tree_outlined, 'Sub-Category:', subCat),
          if (color != 'N/A') _buildDetailRow(Icons.color_lens_outlined, 'Color:', color),
          if (sizeStr != 'N/A' && sizeStr.isNotEmpty) _buildDetailRow(Icons.straighten_outlined, 'Size:', sizeStr),
          if (material != 'N/A') _buildDetailRow(Icons.texture_outlined, 'Material:', material),
          const Divider(height: 24),
          _buildDetailRow(Icons.calendar_today_outlined, 'Order Date:', orderDate),
          _buildDetailRow(Icons.event_available_outlined, 'Delivery Date:', deliveryDate),
          
          if (order.confirmedPrice > 0 || order.unitPrice > 0 || (order.totalAmount > 0 && qty > 0))
            _buildDetailRow(
                Icons.sell_outlined,
                'Unit Price:',
                formatPKR(order.confirmedPrice > 0 
                  ? (order.confirmedPrice / (qty > 0 ? qty : 1))
                  : (order.unitPrice > 0 ? order.unitPrice : (order.totalAmount / (qty > 0 ? qty : 1))))),
          
          if (order.confirmedPrice > 0 || order.totalAmount > 0)
            _buildDetailRow(
                Icons.payments_outlined,
                'Order Value:',
                formatPKR(order.confirmedPrice > 0
                    ? order.confirmedPrice
                    : order.totalAmount)),
          _buildDetailRow(Icons.location_on_outlined, 'Delivery Location:',
              order.deliveryAddress),
          
          if (_extraDetails?['promisedTimeline'] != null || _extraDetails?['vendorTimeline'] != null || _extraDetails?['timeline'] != null)
            _buildDetailRow(Icons.timer_outlined, 'Vendor Timeline:', 
                (_extraDetails?['promisedTimeline'] ?? _extraDetails?['vendorTimeline'] ?? _extraDetails?['timeline']).toString()),
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
              width: 110,
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

  Widget _buildSupportCard(OrderModel order) {
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
                    'threadId': ChatMessage.buildOrderThreadId(
                      orderId: order.id,
                      customerId: order.customerId,
                    ),
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
