import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order.dart';
import '../../../core/constants/app_colors.dart';
import '../../../utils/split_tracking_aggregator.dart';
import '../../../providers/order_provider.dart';

const _primary = Color(0xFF0D5C2F);
const _amber = Color(0xFFC9A93C);
const _red = Color(0xFFD32F2F);

class SplitOrderTrackingWidget extends StatefulWidget {
  final OrderModel order;
  const SplitOrderTrackingWidget({super.key, required this.order});

  @override
  State<SplitOrderTrackingWidget> createState() => _SplitOrderTrackingWidgetState();
}

class _SplitOrderTrackingWidgetState extends State<SplitOrderTrackingWidget> {
  // raw part maps keyed by partId
  Map<String, Map<String, dynamic>> _partsMap = {};
  StreamSubscription? _sub;
  bool _loading = true;
  // which vendor cards are expanded
  final Set<String> _expanded = {};

  Map<String, dynamic>? _extraDetails;

  @override
  void initState() {
    super.initState();
    _initListener();
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

  void _initListener() {
    final subOrderIds = widget.order.subOrders;
    
    if (subOrderIds.isNotEmpty) {
      debugPrint('>>> SplitOrderTrackingWidget: Listening to subOrders collection for IDs: $subOrderIds');
      // Listen to top-level subOrders collection
      _sub = FirebaseFirestore.instance
          .collection('subOrders')
          .where(FieldPath.documentId, whereIn: subOrderIds)
          .snapshots()
          .listen(_handleSnapshot, onError: (e) {
            debugPrint('>>> SplitOrderTrackingWidget: Error listening to subOrders: $e');
            setState(() { _loading = false; });
          });
    } else {
      debugPrint('>>> SplitOrderTrackingWidget: Listening to orderParts sub-collection for parent: ${widget.order.id}');
      // Listen to sub-collection (legacy/internal)
      _sub = FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.id)
          .collection('orderParts')
          .snapshots()
          .listen(_handleSnapshot, onError: (e) {
            debugPrint('>>> SplitOrderTrackingWidget: Error listening to orderParts: $e');
            setState(() { _loading = false; });
          });
    }
  }

  void _handleSnapshot(QuerySnapshot snap) {
    if (!mounted) return;
    final Map<String, Map<String, dynamic>> m = {};
    for (final doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      var rawSteps = d['trackingSteps'] as List?;
      
      // Fallback to 'timeline' if trackingSteps is missing
      if (rawSteps == null || rawSteps.isEmpty) {
        final rawTimeline = d['timeline'] as List?;
        if (rawTimeline != null && rawTimeline.isNotEmpty) {
          rawSteps = rawTimeline.map((t) => {
            'stepId': t['step'] ?? '',
            'title': t['step'] ?? '',
            'description': t['note'] ?? '',
            'status': (t['completed'] == true || t['completed'] == 1) ? 'completed' : 'pending',
            'completedAt': t['date'],
            'expectedDate': t['date'],
          }).toList();
        }
      }
      
      // Use assignedQuantity if quantity is missing (vendor app field mapping)
      final qty = d['quantity'] ?? d['assignedQuantity'] ?? 0;
      
      m[doc.id] = {
        'vendorId': d['vendorId'] ?? '',
        'vendorName': d['vendorName'] ?? 'Vendor',
        'quantity': qty,
        'unit': d['unit'] ?? 'units',
        'status': d['status'] ?? '',
        'trackingNumber': d['trackingNumber'],
        'vendorTimeline': d['vendorTimeline'] ?? d['productionTimeline'] ?? 'N/A',
        'steps': rawSteps != null 
            ? List<Map<String, dynamic>>.from(rawSteps.map((s) => Map<String, dynamic>.from(s as Map))) 
            : <Map<String, dynamic>>[],
      };
    }
    
    if (mounted) {
      setState(() { 
        _partsMap = m; 
        _loading = false; 
      });

      // Auto-completion check
      _checkAutoCompletion();
    }
  }

  void _checkAutoCompletion() {
    if (widget.order.status.toLowerCase() == 'completed') return;
    
    if (_partsMap.isEmpty) return;
    
    final result = SplitTrackingAggregator.compute(_partsMap.values.toList());
    if (result != null && result.isFullyCompleted) {
      debugPrint('>>> SplitOrderTrackingWidget: All parts completed. Updating parent order status...');
      // All parts are completed, update parent order status
      context.read<OrderProvider>().markOrderAsCompleted(widget.order.id);
    }
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  // Build the aggregator-friendly parts list
  List<Map<String, dynamic>> get _aggregatorParts => _partsMap.values.toList();

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: _primary)));

    final result = SplitTrackingAggregator.compute(_aggregatorParts);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrderHeaderCard(order: widget.order),
          const SizedBox(height: 16),
          _OrderDetailsCard(
            order: widget.order, 
            extraDetails: _extraDetails, 
            qty: _getValidQuantity(),
            maxVendorTimeline: _calculateMaxVendorTimeline(),
          ),
          const SizedBox(height: 16),
          if (result != null) ...[
            _UnifiedProgressCard(result: result),
            const SizedBox(height: 24),
            _UnifiedTimeline(result: result),
            const SizedBox(height: 24),
          ] else ...[
            _SimpleProgressCard(partsMap: _partsMap),
            const SizedBox(height: 24),
          ],
          // Vendor breakdown (expandable)
          _VendorBreakdownSection(
            partsMap: _partsMap,
            expanded: _expanded,
            onToggle: (id) => setState(() => _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String? _calculateMaxVendorTimeline() {
    if (_partsMap.isEmpty) return null;
    int maxDays = 0;
    String? maxStr;
    
    for (final part in _partsMap.values) {
      final timeline = part['vendorTimeline']?.toString();
      if (timeline != null && timeline != 'N/A') {
        final match = RegExp(r'(\d+)').firstMatch(timeline);
        if (match != null) {
          final days = int.tryParse(match.group(1)!);
          if (days != null && days > maxDays) {
            maxDays = days;
            maxStr = timeline;
          }
        } else {
          final days = int.tryParse(timeline);
          if (days != null && days > maxDays) {
            maxDays = days;
            maxStr = timeline;
          }
        }
      }
    }
    return maxStr;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Order Header Card
// ──────────────────────────────────────────────────────────────────────────────
class _OrderHeaderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderHeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.divider)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Order Number', style: TextStyle(color: AppColors.textMedium, fontSize: 12)),
                Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ]),
              _StatusBadge(status: order.status),
            ],
          ),
          if (order.customerPrice > 0) ...[
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total Paid', style: TextStyle(fontSize: 14)),
              Text(formatPKR(order.customerPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primary)),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Order Details Card
// ──────────────────────────────────────────────────────────────────────────────
class _OrderDetailsCard extends StatelessWidget {
  final OrderModel order;
  final Map<String, dynamic>? extraDetails;
  final int qty;
  final String? maxVendorTimeline;
  
  const _OrderDetailsCard({required this.order, required this.extraDetails, required this.qty, this.maxVendorTimeline});

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return 'N/A';
    }
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
                  style: const TextStyle(fontSize: 12, color: AppColors.textMedium))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String cat = extraDetails?['category'] ?? extraDetails?['step1Category'] ?? 'N/A';
    final String subCat = extraDetails?['subCategory'] ?? extraDetails?['step1SubCategory'] ?? 'N/A';
    final String color = extraDetails?['color'] ?? extraDetails?['step1Color'] ?? 'N/A';
    final String material = extraDetails?['material'] ?? extraDetails?['step1Material'] ?? 'N/A';
    
    String sizeStr = 'N/A';
    if (extraDetails?['size'] != null && extraDetails!['size'].toString().isNotEmpty) {
      sizeStr = extraDetails!['size'].toString();
    } else if (extraDetails?['step2Measurements'] != null) {
      final meas = extraDetails!['step2Measurements'];
      if (meas is Map) {
        sizeStr = meas.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      }
    } else if (extraDetails?['dimensions'] != null) {
      sizeStr = extraDetails!['dimensions'].toString();
    }

    final String orderDate = _formatDate(order.createdAt);
    
    String deliveryDate = 'N/A';
    if (order.expectedDelivery.isNotEmpty) {
      deliveryDate = order.expectedDelivery;
    } else if (extraDetails?['expectedDelivery'] != null) {
      deliveryDate = extraDetails!['expectedDelivery'].toString();
    } else if (extraDetails?['deliveryDate'] != null) {
      deliveryDate = extraDetails!['deliveryDate'].toString();
    } else if (extraDetails?['deadline'] != null) {
      deliveryDate = extraDetails!['deadline'].toString();
    } else if (extraDetails?['timeline'] != null || extraDetails?['step1Timeline'] != null) {
      // Calculate from timeline (lead time in days)
      final timelineVal = extraDetails?['timeline'] ?? extraDetails?['step1Timeline'];
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
        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        deliveryDate = '${date.day} ${months[date.month - 1]} ${date.year}';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
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
              if (extraDetails != null) {
                pName = extraDetails!['productName'] ?? extraDetails!['step1ProductName'] ?? extraDetails!['productType'] ?? pName;
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
          
          if (maxVendorTimeline != null)
            _buildDetailRow(Icons.timer_outlined, 'Vendor Timeline:', maxVendorTimeline!),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Unified Progress Card (aggregated)
// ──────────────────────────────────────────────────────────────────────────────
class _UnifiedProgressCard extends StatelessWidget {
  final SplitTrackingResult result;
  const _UnifiedProgressCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final pct = result.overallProgressPercent;
    final barColor = result.hasQcIssue && result.unifiedTimeline.any((m) => m.isRejected)
        ? _red
        : result.hasQcIssue ? _amber : _primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: barColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: barColor.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(result.hasQcIssue ? Icons.warning_rounded : Icons.track_changes_rounded, color: barColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(result.currentStatusText,
                style: TextStyle(color: barColor, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Text('$pct%', style: TextStyle(color: barColor, fontWeight: FontWeight.w900, fontSize: 20)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${result.unifiedTimeline.where((m) => m.isCompleted).length} of ${result.unifiedTimeline.length} milestones complete',
          style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
        ),
        if (result.hasQcIssue) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: _red.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.info_outline, color: _red, size: 14),
              const SizedBox(width: 6),
              const Expanded(child: Text('One or more items need attention. Check vendor details below.', style: TextStyle(color: _red, fontSize: 11))),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Fallback simple progress (no steps)
// ──────────────────────────────────────────────────────────────────────────────
class _SimpleProgressCard extends StatelessWidget {
  final Map<String, Map<String, dynamic>> partsMap;
  const _SimpleProgressCard({required this.partsMap});

  @override
  Widget build(BuildContext context) {
    final total = partsMap.length;
    final delivered = partsMap.values.where((p) => p['status'] == 'delivered').length;
    final pct = total > 0 ? delivered / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _primary.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: _primary.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$delivered of $total shipments delivered', style: const TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: pct, backgroundColor: AppColors.divider, valueColor: const AlwaysStoppedAnimation<Color>(_primary), minHeight: 8)),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Unified Timeline
// ──────────────────────────────────────────────────────────────────────────────
class _UnifiedTimeline extends StatelessWidget {
  final SplitTrackingResult result;
  const _UnifiedTimeline({required this.result});

  String _fmt(DateTime? dt) {
    if (dt == null) return 'N/A';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${m[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final milestones = result.unifiedTimeline;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Order Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      const Text('Merged across all vendors', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
      const SizedBox(height: 16),
      ...milestones.asMap().entries.map((e) {
        final i = e.key;
        final m = e.value;
        return _MilestoneRow(milestone: m, isLast: i == milestones.length - 1, formatDate: _fmt);
      }),
    ]);
  }
}

class _MilestoneRow extends StatelessWidget {
  final MergedMilestone milestone;
  final bool isLast;
  final String Function(DateTime?) formatDate;
  const _MilestoneRow({required this.milestone, required this.isLast, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final m = milestone;
    Color dotColor;
    IconData dotIcon;
    Color lineColor = AppColors.divider;

    if (m.isRejected) { dotColor = _red; dotIcon = Icons.priority_high; }
    else if (m.isUnderReview) { dotColor = _amber; dotIcon = Icons.hourglass_empty; }
    else if (m.isCompleted) { dotColor = _primary; dotIcon = Icons.check; lineColor = _primary; }
    else if (m.isInProgress) { dotColor = _primary; dotIcon = Icons.play_arrow; }
    else { dotColor = AppColors.divider; dotIcon = Icons.circle_outlined; }

    final dotFilled = m.isCompleted || m.isInProgress || m.isRejected || m.isUnderReview;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: dotFilled ? dotColor : Colors.white,
            border: Border.all(color: dotColor, width: 2),
            shape: BoxShape.circle,
          ),
          child: Icon(dotFilled ? dotIcon : null, color: Colors.white, size: 14),
        ),
        if (!isLast) Container(width: 2, height: 64, color: lineColor),
      ]),
      const SizedBox(width: 12),
      Expanded(
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: m.isRejected ? _red.withOpacity(0.05) : m.isUnderReview ? _amber.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: m.isRejected ? _red.withOpacity(0.3) : m.isUnderReview ? _amber.withOpacity(0.3) : AppColors.divider),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              Text(
                m.isCompleted ? formatDate(m.latestCompletedAt) : 'Exp: ${formatDate(m.earliestExpectedAt)}',
                style: const TextStyle(color: AppColors.textLight, fontSize: 11),
              ),
            ]),
            if (m.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(m.description, style: const TextStyle(color: AppColors.textMedium, fontSize: 11)),
            ],
            const SizedBox(height: 6),
            Row(children: [
              _statusChip(m),
              const SizedBox(width: 8),
              if (m.totalCount > 1)
                Text('${m.completedCount}/${m.totalCount} vendors',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMedium)),
            ]),
            if (m.qcFeedbackItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Note: ${m.qcFeedbackItems.join('; ')}', style: const TextStyle(color: _red, fontSize: 11, fontWeight: FontWeight.w500)),
              ),
          ]),
        ),
      ),
    ]);
  }

  Widget _statusChip(MergedMilestone m) {
    String label; Color bg; Color fg;
    if (m.isRejected) { label = '⚠ Correction Needed'; bg = _red.withOpacity(0.1); fg = _red; }
    else if (m.isUnderReview) { label = '⧖ Quality Check'; bg = _amber.withOpacity(0.1); fg = _amber; }
    else if (m.isCompleted) { label = '✓ Completed'; bg = _primary.withOpacity(0.08); fg = _primary; }
    else if (m.isInProgress) { label = '● In Progress'; bg = _amber.withOpacity(0.1); fg = const Color(0xFF8A6000); }
    else { label = '○ Pending'; bg = AppColors.divider.withOpacity(0.3); fg = AppColors.textMedium; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Vendor Breakdown (expandable)
// ──────────────────────────────────────────────────────────────────────────────
class _VendorBreakdownSection extends StatelessWidget {
  final Map<String, Map<String, dynamic>> partsMap;
  final Set<String> expanded;
  final void Function(String) onToggle;
  const _VendorBreakdownSection({required this.partsMap, required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    if (partsMap.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Vendor Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      const Text('Tap a vendor to see their individual steps', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
      const SizedBox(height: 12),
      ...partsMap.entries.map((e) => _VendorCard(
        partId: e.key,
        partData: e.value,
        isExpanded: expanded.contains(e.key),
        onToggle: () => onToggle(e.key),
      )),
    ]);
  }
}

class _VendorCard extends StatelessWidget {
  final String partId;
  final Map<String, dynamic> partData;
  final bool isExpanded;
  final VoidCallback onToggle;
  const _VendorCard({required this.partId, required this.partData, required this.isExpanded, required this.onToggle});

  String _fmt(dynamic ts) {
    if (ts == null) return 'N/A';
    try { final d = (ts as Timestamp).toDate(); const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']; return '${d.day} ${m[d.month-1]}'; } catch (_) { return 'N/A'; }
  }

  @override
  Widget build(BuildContext context) {
    final steps = partData['steps'] as List<Map<String, dynamic>>;
    final vendorName = partData['vendorName'] as String? ?? 'Vendor';
    final qty = partData['quantity'];
    final unit = partData['unit'] as String? ?? 'units';
    final status = partData['status'] as String? ?? '';
    final completedSteps = steps.where((s) => s['status'] == 'completed').length;
    final vendorPct = steps.isNotEmpty ? (completedSteps / steps.length * 100).round() : 0;

    // status color
    Color statusColor = _primary;
    if (status == 'rejected') statusColor = _red;
    else if (status == 'under_review' || status == 'ready-to-ship') statusColor = _amber;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        // Header row
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: _primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.store_outlined, color: _primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(vendorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('$qty $unit · $vendorPct% complete', style: const TextStyle(color: AppColors.textMedium, fontSize: 11)),
                if (partData['vendorTimeline'] != 'N/A')
                  Text('Promised: ${partData['vendorTimeline']}', style: const TextStyle(color: _primary, fontSize: 10, fontWeight: FontWeight.bold)),
              ])),
              // mini progress
              SizedBox(
                width: 60,
                child: Column(children: [
                  Text('$vendorPct%', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: vendorPct / 100, backgroundColor: AppColors.divider, valueColor: AlwaysStoppedAnimation<Color>(statusColor), minHeight: 5),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textMedium),
            ]),
          ),
        ),
        // Expanded steps
        if (isExpanded && steps.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
            child: Column(
              children: steps.asMap().entries.map((e) {
                final idx = e.key; final step = e.value;
                final done = step['status'] == 'completed';
                final prog = step['status'] == 'in-progress';
                final rev = step['status'] == 'under_review';
                final rej = step['status'] == 'rejected';
                Color c = done ? _primary : prog ? _primary : rev ? _amber : rej ? _red : AppColors.divider;
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Column(children: [
                    const SizedBox(height: 14),
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(color: (done || prog || rev || rej) ? c : Colors.white, border: Border.all(color: c, width: 1.5), shape: BoxShape.circle),
                      child: Icon(done ? Icons.check : prog ? Icons.play_arrow : rev ? Icons.hourglass_empty : rej ? Icons.priority_high : null, color: Colors.white, size: 12),
                    ),
                    if (idx < steps.length - 1) Container(width: 2, height: 44, color: done ? _primary : AppColors.divider),
                  ]),
                  const SizedBox(width: 10),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(step['title'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        Text(done ? _fmt(step['completedAt']) : 'Exp: ${_fmt(step['expectedDate'])}', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                      ]),
                      if ((step['description'] as String? ?? '').isNotEmpty)
                        Text(step['description'], style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                      if (rej && step['qcFeedback'] != null)
                        Text('⚠ ${step['qcFeedback']}', style: const TextStyle(fontSize: 11, color: _red, fontWeight: FontWeight.w500)),
                      // media
                      if ((done || rev || rej) && (step['mediaUrls'] != null || step['images'] != null))
                        _MediaRow(urls: List<String>.from((step['mediaUrls'] ?? step['images']) as List)),
                    ]),
                  )),
                ]);
              }).toList(),
            ),
          ),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Media Row
// ──────────────────────────────────────────────────────────────────────────────
class _MediaRow extends StatelessWidget {
  final List<String> urls;
  const _MediaRow({required this.urls});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SizedBox(
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: urls.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (ctx, i) {
            final url = urls[i];
            final isVideo = url.contains('.mp4') || url.contains('video_');
            return GestureDetector(
              onTap: () => _openFullscreen(ctx, url, isVideo: isVideo),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 56, height: 56,
                  child: isVideo
                      ? Container(color: Colors.black12, child: const Center(child: Icon(Icons.play_circle_fill, color: _primary, size: 28)))
                      : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))),
                          errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: AppColors.textLight)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext ctx, String url, {bool isVideo = false}) {
    Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), elevation: 0),
      body: Center(child: isVideo
          ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.videocam, color: Colors.white, size: 64),
              SizedBox(height: 16),
              Text('Video preview', style: TextStyle(color: Colors.white)),
            ])
          : InteractiveViewer(child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain,
              placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
              errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 64)))),
    )));
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = _primary.withOpacity(0.1); Color fg = _primary;
    if (status == 'completed') { bg = Colors.green.shade100; fg = Colors.green.shade700; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(status.replaceAll('_', ' ').replaceAll('-', ' ').toUpperCase(), style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
