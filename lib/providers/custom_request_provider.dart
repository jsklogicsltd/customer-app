import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/custom_request.dart';

class CustomRequestProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<CustomRequest> _requests = [];
  bool _isLoading = true;
  StreamSubscription? _requestsSub;

  // ── Step 1: Product Selection ──────────────────────────────────────────
  String step1Category = '';
  String step1SubCategory = '';
  String step1ProductType = '';
  String step1Description = '';
  List<XFile> step1Images = []; // Cross-platform images

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
    _init();
  }

  bool get isLoading => _isLoading;
  List<CustomRequest> get allRequests => _requests;

  void _init() {
    _auth.authStateChanges().listen((user) {
      _requestsSub?.cancel();
      if (user != null) {
        _requestsSub = _db
            .collection('customRequests')
            .where('customerId', isEqualTo: user.uid)
            .orderBy('submittedDate', descending: true)
            .snapshots()
            .listen((snapshot) {
          _requests = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return CustomRequest.fromMap(data);
          }).toList();
          _isLoading = false;
          notifyListeners();
        }, onError: (e) {
          debugPrint('Error in CustomRequestProvider listener: $e');
          _isLoading = false;
          notifyListeners();
        });
      } else {
        _requests = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _requestsSub?.cancel();
    super.dispose();
  }

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
    step3BudgetMin = 0;
    step3BudgetMax = 0;
    step3Deadline = '';
    step3DeliveryType = 'domestic';
    step3Packaging = 'standard';
    notifyListeners();
  }

  Future<String> submitRequest() async {
    final user = _auth.currentUser;
    if (user == null) throw 'User must be logged in to submit a request';

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Upload Images
      List<String> remoteImageUrls = [];
      for (int i = 0; i < step1Images.length; i++) {
        final xfile = step1Images[i];
        final ref = _storage.ref('custom_requests/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        
        // putData works on both Web and Mobile
        await ref.putData(await xfile.readAsBytes());
        
        final url = await ref.getDownloadURL();
        remoteImageUrls.add(url);
      }

      final productLabel = step1ProductType.isNotEmpty
          ? step1ProductType
          : step1SubCategory.isNotEmpty
              ? step1SubCategory
              : step1Category;

      // 2. Save to Firestore
      final newRequest = {
        'customerId': user.uid,
        'category': step1Category,
        'subCategory': step1SubCategory,
        'productType': productLabel,
        'description': step1Description,
        'quantity': step2Quantity,
        'sizes': step2Sizes,
        'color': step2Color,
        'material': step2Material,
        'budgetMin': step3BudgetMin,
        'budgetMax': step3BudgetMax,
        'deadline': step3Deadline,
        'deliveryType': step3DeliveryType,
        'packaging': step3Packaging,
        'status': 'pending',
        'submittedDate': DateTime.now().toIso8601String(),
        'referenceImages': remoteImageUrls,
        'timeline': [
          {
            'step': 'Request Submitted',
            'date': DateTime.now().toIso8601String(),
            'completed': true,
            'current': false,
          },
          {
            'step': 'Under Review by Our Team',
            'date': '',
            'completed': false,
            'current': true,
          },
          {'step': 'Quote Prepared', 'date': '', 'completed': false, 'current': false},
          {'step': 'Confirmation Pending', 'date': '', 'completed': false, 'current': false},
          {'step': 'Order Created', 'date': '', 'completed': false, 'current': false},
        ],
      };

      final docRef = await _db.collection('customRequests').add(newRequest);
      clearForm();
      return docRef.id;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setLastSubmittedId(String id) {
    lastSubmittedId = id;
    notifyListeners();
  }

  Future<void> acceptQuote(String requestId, String orderId) async {
    await _db.collection('customRequests').doc(requestId).update({
      'status': 'confirmed',
      'confirmedOrderId': orderId,
      'timeline': FieldValue.arrayUnion([
        {
          'step': 'Quote Accepted',
          'date': DateTime.now().toIso8601String(),
          'completed': true,
        }
      ]),
    });
  }
}
