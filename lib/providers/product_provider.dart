import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> products = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _categoryFilter;
  String _sortBy = 'popular';

  bool get isLoading => _isLoading;

  Future<void> fetchProducts({String? category}) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('=== Fetching products ===');
      Query query = FirebaseFirestore.instance
          .collection('products')
          .where('status', isEqualTo: 'active')
          .where('isDraft', isEqualTo: false);
      
      final snapshot = await query.get();

      print('Total products found: ${snapshot.docs.length}');

      products = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromMap(data, doc.id);
      }).toList();

    } catch (e) {
      print('ERROR fetching products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Product> get filteredProducts {
    var list = products.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.productName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _categoryFilter == null ||
          p.category == _categoryFilter ||
          p.subCategory == _categoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();

    switch (_sortBy) {
      case 'price_low':
        list.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
        break;
      case 'price_high':
        list.sort((a, b) => b.unitPrice.compareTo(a.unitPrice));
        break;
      default:
        // default sorting
    }
    return list;
  }

  Product? getById(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Product> getByVendor(String vendorId) =>
      products.where((p) => p.vendorId == vendorId).toList();

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  List<Product> getSaved(List<String> ids) {
    return products.where((p) => ids.contains(p.id)).toList();
  }

  List<Product> getProductsByCategory(String categoryName) {
    final normalizedSearch = categoryName.toLowerCase().replaceAll("'s", "").replaceAll(" ", "");
    return products.where((p) {
      final normalizedCategory = p.category.toLowerCase().replaceAll("'s", "").replaceAll(" ", "");
      return normalizedCategory == normalizedSearch;
    }).toList();
  }

  void clearFilters() {
    _searchQuery = '';
    _categoryFilter = null;
    _sortBy = 'popular';
    notifyListeners();
  }
}
