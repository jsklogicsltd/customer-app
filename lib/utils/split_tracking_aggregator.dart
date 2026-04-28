/// split_tracking_aggregator.dart
///
/// Pure Dart utility — no Flutter/Firebase imports.
/// Aggregates multiple vendor orderPart tracking maps into a single unified
/// progress result using quantity-weighted averaging.
///
/// Usage:
///   final result = SplitTrackingAggregator.compute(parts);
///   print(result.overallProgressPercent);  // 0–100
library;

// ─── Data models ─────────────────────────────────────────────────────────────

/// Represents one merged milestone across all vendors for the same step.
class MergedMilestone {
  final String stepId;
  final String title;
  final String description;

  /// Aggregate status across vendors.
  /// "completed"  → every vendor has completed this step
  /// "in-progress" → at least one vendor is in-progress (and none pending)
  /// "under_review" → at least one under_review, none rejected
  /// "rejected"   → at least one vendor has a rejected step
  /// "pending"    → step not yet started by all vendors
  final String overallStatus;

  /// How many vendors have completed this step.
  final int completedCount;
  final int totalCount;

  /// Latest completedAt across vendors (so the milestone is shown as
  /// finished once the LAST vendor completes it).
  final DateTime? latestCompletedAt;

  /// Earliest expectedDate for context.
  final DateTime? earliestExpectedAt;

  /// Any QC feedback from rejected steps (collected from all parts).
  final List<String> qcFeedbackItems;

  const MergedMilestone({
    required this.stepId,
    required this.title,
    required this.description,
    required this.overallStatus,
    required this.completedCount,
    required this.totalCount,
    this.latestCompletedAt,
    this.earliestExpectedAt,
    this.qcFeedbackItems = const [],
  });

  bool get isCompleted => overallStatus == 'completed';
  bool get isInProgress => overallStatus == 'in-progress';
  bool get isPending => overallStatus == 'pending';
  bool get isUnderReview => overallStatus == 'under_review';
  bool get isRejected => overallStatus == 'rejected';
}

/// Result of the aggregation.
class SplitTrackingResult {
  /// 0–100 weighted overall progress.
  final int overallProgressPercent;

  /// Human-readable status text for the circular indicator.
  final String currentStatusText;

  /// Merged milestone list in the correct display order.
  final List<MergedMilestone> unifiedTimeline;

  /// True if any vendor has a rejected or under_review step right now.
  final bool hasQcIssue;

  /// True if all vendors have all steps completed.
  final bool isFullyCompleted;

  const SplitTrackingResult({
    required this.overallProgressPercent,
    required this.currentStatusText,
    required this.unifiedTimeline,
    required this.hasQcIssue,
    required this.isFullyCompleted,
  });
}

// ─── Aggregator ──────────────────────────────────────────────────────────────

class SplitTrackingAggregator {
  SplitTrackingAggregator._();

  /// [parts] is the list of `orderPart` data maps, each containing:
  ///   - 'quantity' (int)
  ///   - 'vendorName' (String)
  ///   - 'steps' (List<Map<String, dynamic>>)   ← tracking steps
  ///
  /// Returns null if parts is empty or no steps exist anywhere.
  static SplitTrackingResult? compute(
      List<Map<String, dynamic>> parts) {
    if (parts.isEmpty) return null;

    // Filter to only parts that have tracking steps
    final partsWithSteps =
        parts.where((p) => (p['steps'] as List?)?.isNotEmpty == true).toList();
    if (partsWithSteps.isEmpty) return null;

    // ── 1. Compute weighted progress ────────────────────────────────────────
    double totalWeight = 0;
    double weightedSum = 0;

    for (final part in partsWithSteps) {
      final qty = _toDouble(part['quantity']);
      final weight = qty > 0 ? qty : 1.0; // treat 0-quantity as 1 to avoid division by zero
      final steps = part['steps'] as List;
      if (steps.isEmpty) continue;

      int maxPercentage = 0;
      for (final s in steps) {
        if (s['status'] == 'completed') {
          final p = (s['percentage'] as num?)?.toInt() ?? 0;
          if (p > maxPercentage) maxPercentage = p;
        }
      }
      double partProgress = maxPercentage / 100.0;
      if (partProgress == 0 && steps.isNotEmpty) {
        final completedCount = steps.where((s) => s['status'] == 'completed').length;
        partProgress = completedCount / steps.length;
      }

      totalWeight += weight;
      weightedSum += partProgress * weight;
    }

    final rawProgress =
        totalWeight > 0 ? (weightedSum / totalWeight) * 100 : 0.0;
    int overallPercent = rawProgress.round().clamp(0, 100);

    bool allPartsTerminal = true;
    for (final part in partsWithSteps) {
      final st = (part['status'] as String?)?.toLowerCase();
      if (st != 'completed' && st != 'delivered') {
        allPartsTerminal = false;
        break;
      }
    }
    if (allPartsTerminal) overallPercent = 100;

    // ── 2. Merge milestones by stepId ───────────────────────────────────────
    // Collect all unique stepIds while preserving insertion order
    final stepOrder = <String>[];
    final stepTitles = <String, String>{};
    final stepDescriptions = <String, String>{};

    for (final part in partsWithSteps) {
      for (final step in (part['steps'] as List)) {
        final id = (step['stepId'] as String?) ?? (step['title'] as String?) ?? '';
        if (id.isNotEmpty && !stepOrder.contains(id)) {
          stepOrder.add(id);
          stepTitles[id] = step['title'] as String? ?? id;
          stepDescriptions[id] = step['description'] as String? ?? '';
        }
      }
    }

    // For each stepId, aggregate across all parts
    final mergedMilestones = <MergedMilestone>[];
    bool hasQcIssue = false;

    for (final stepId in stepOrder) {
      final matchingSteps = <Map<String, dynamic>>[];
      for (final part in partsWithSteps) {
        for (final step in (part['steps'] as List)) {
          final id = (step['stepId'] as String?) ?? (step['title'] as String?) ?? '';
          if (id == stepId) {
            matchingSteps.add(Map<String, dynamic>.from(step));
          }
        }
      }
      if (matchingSteps.isEmpty) continue;

      final total = partsWithSteps.length;

      // Count statuses
      int completedCount = 0;
      int inProgressCount = 0;
      int underReviewCount = 0;
      int rejectedCount = 0;
      DateTime? latestCompletedAt;
      DateTime? earliestExpected;
      final qcItems = <String>[];

      for (final step in matchingSteps) {
        final st = step['status'] as String? ?? 'pending';
        if (st == 'completed') {
          completedCount++;
          final ts = _parseTimestamp(step['completedAt']);
          if (ts != null &&
              (latestCompletedAt == null || ts.isAfter(latestCompletedAt!))) {
            latestCompletedAt = ts;
          }
        } else if (st == 'in-progress') {
          inProgressCount++;
        } else if (st == 'under_review') {
          underReviewCount++;
          hasQcIssue = true;
        } else if (st == 'rejected') {
          rejectedCount++;
          hasQcIssue = true;
          final fb = step['qcFeedback'] as String?;
          if (fb != null && fb.isNotEmpty) qcItems.add(fb);
        }

        final expTs = _parseTimestamp(step['expectedDate']);
        if (expTs != null &&
            (earliestExpected == null || expTs.isBefore(earliestExpected!))) {
          earliestExpected = expTs;
        }
      }

      // Derive overall status for this milestone
      String overallStatus;
      if (rejectedCount > 0) {
        overallStatus = 'rejected';
      } else if (underReviewCount > 0) {
        overallStatus = 'under_review';
      } else if (completedCount == total) {
        overallStatus = 'completed';
      } else if (inProgressCount > 0 || completedCount > 0) {
        overallStatus = 'in-progress';
      } else {
        overallStatus = 'pending';
      }

      mergedMilestones.add(MergedMilestone(
        stepId: stepId,
        title: stepTitles[stepId] ?? stepId,
        description: stepDescriptions[stepId] ?? '',
        overallStatus: overallStatus,
        completedCount: completedCount,
        totalCount: total,
        latestCompletedAt: latestCompletedAt,
        earliestExpectedAt: earliestExpected,
        qcFeedbackItems: qcItems,
      ));
    }

    // ── 3. Derive current status text ───────────────────────────────────────
    final isFullyCompleted = overallPercent == 100 ||
        mergedMilestones.every((m) => m.isCompleted);

    String statusText;
    if (hasQcIssue && mergedMilestones.any((m) => m.isRejected)) {
      statusText = 'Action Required';
    } else if (hasQcIssue && mergedMilestones.any((m) => m.isUnderReview)) {
      statusText = 'Quality Check in Progress';
    } else if (isFullyCompleted) {
      statusText = 'Order Completed';
    } else {
      // Show the slowest part's in-progress or last completed step
      final inProgressMilestone =
          mergedMilestones.firstWhere((m) => m.isInProgress, orElse: () {
        return mergedMilestones.lastWhere((m) => m.isCompleted,
            orElse: () => mergedMilestones.first);
      });
      statusText = inProgressMilestone.title;
    }

    return SplitTrackingResult(
      overallProgressPercent: overallPercent,
      currentStatusText: statusText,
      unifiedTimeline: mergedMilestones,
      hasQcIssue: hasQcIssue,
      isFullyCompleted: isFullyCompleted,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static DateTime? _parseTimestamp(dynamic ts) {
    if (ts == null) return null;
    try {
      // Firestore Timestamp
      return (ts as dynamic).toDate() as DateTime;
    } catch (_) {
      try {
        if (ts is String) return DateTime.tryParse(ts);
      } catch (_) {}
      return null;
    }
  }
}
