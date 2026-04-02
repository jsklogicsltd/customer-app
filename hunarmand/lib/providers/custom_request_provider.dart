import 'package:flutter/foundation.dart';
import '../data/mock/mock_custom_requests.dart';
import '../models/custom_request.dart';

class CustomRequestProvider extends ChangeNotifier {
  late List<CustomRequest> _requests;
  int _reqCounter = 91;

  // ── Step 1: Product Selection ──────────────────────────────────────────
  String step1Category = '';
  String step1SubCategory = '';
  String step1ProductType = '';
  String step1Description = '';
  List<String> step1Images = [];

  // ── Step 2: Specifications ─────────────────────────────────────────────
  int step2Quantity = 1;
  List<String> step2Sizes = [];
  String step2Color = '';
  String step2Material = '';
  String step2SpecialFeatures = '';

  // ── Step 3: Budget & Requirements ─────────────────────────────────────
  int step3BudgetMin = 0;
  int step3BudgetMax = 0;
  String step3Deadline = '';
  String step3DeliveryType = 'domestic';
  String step3Packaging = 'standard';

  String? lastSubmittedId;

  CustomRequestProvider() {
    _requests = List.from(mockCustomRequestsData);
  }

  List<CustomRequest> get allRequests => _requests;

  CustomRequest? getById(String id) {
    try {
      return _requests.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearForm() {
    step1Category = '';
    step1SubCategory = '';
    step1ProductType = '';
    step1Description = '';
    step1Images = [];
    step2Quantity = 1;
    step2Sizes = [];
    step2Color = '';
    step2Material = '';
    step2SpecialFeatures = '';
    step3BudgetMin = 0;
    step3BudgetMax = 0;
    step3Deadline = '';
    step3DeliveryType = 'domestic';
    step3Packaging = 'standard';
    notifyListeners();
  }

  String submitRequest() {
    final id = 'REQ-2026-0$_reqCounter';
    _reqCounter++;

    final productLabel = step1ProductType.isNotEmpty
        ? step1ProductType
        : step1SubCategory.isNotEmpty
            ? step1SubCategory
            : step1Category;

    final newRequest = CustomRequest(
      id: id,
      category: step1Category,
      subCategory: step1SubCategory,
      productType: productLabel,
      description: step1Description,
      quantity: step2Quantity,
      sizes: step2Sizes,
      color: step2Color,
      material: step2Material,
      budgetMin: step3BudgetMin,
      budgetMax: step3BudgetMax,
      deadline: step3Deadline,
      deliveryType: step3DeliveryType,
      packaging: step3Packaging,
      status: 'pending',
      submittedDate: DateTime.now().toIso8601String().split('T').first,
      referenceImages: step1Images.isNotEmpty ? step1Images : null,
      timeline: [
        const RequestTimeline(
            step: 'Request Submitted', date: 'Just now', completed: true),
        const RequestTimeline(
            step: 'Under Review by Our Team',
            date: 'In progress...',
            completed: false,
            current: true),
        const RequestTimeline(
            step: 'Quote Prepared', date: '', completed: false),
        const RequestTimeline(
            step: 'Quote Sent to You', date: '', completed: false),
        const RequestTimeline(
            step: 'Your Confirmation Pending', date: '', completed: false),
        const RequestTimeline(
            step: 'Order Created & Live', date: '', completed: false),
      ],
    );

    _requests.insert(0, newRequest);
    lastSubmittedId = id;
    clearForm();
    return id;
  }

  void acceptQuote(String requestId) {
    final req = getById(requestId);
    if (req != null) {
      req.status = 'confirmed';
      notifyListeners();
    }
  }
}
