import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../data/mock/mock_categories.dart';

class CategoryProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<AppCategory> _categories = [];
  List<Map<String, dynamic>> _hierarchy = mockCategoriesHierarchy;
  bool _isLoading = false;
  StreamSubscription? _sub;
  StreamSubscription? _hierSub;

  CategoryProvider() {
    _init();
    _initHierarchy();
  }

  bool get isLoading => _isLoading;
  List<AppCategory> get allCategories => _categories;
  List<Map<String, dynamic>> get hierarchy => _hierarchy;

  void _init() {
    _sub = _db.collection('Categories').snapshots().listen((snapshot) {
      try {
        _categories = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return AppCategory.fromMap(data);
        }).toList();
        debugPrint('CategoryProvider: ${_categories.length} categories loaded');
      } catch (e) {
        debugPrint('Error parsing categories: $e');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('Error fetching categories: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  void _initHierarchy() {
    _hierSub = _db.collection('metadata').doc('category_hierarchy').snapshots().listen((snap) {
      if (snap.exists && snap.data() != null) {
        _hierarchy = List<Map<String, dynamic>>.from(snap.data()!['data'] as List);
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _hierSub?.cancel();
    super.dispose();
  }

  AppCategory? getByName(String name) {
    try {
      return _categories.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }
}
