import 'package:flutter/material.dart';
import '../data/mock/mock_products.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  late List<AppProduct> _products;
  String _searchQuery = '';
  String? _categoryFilter;
  String _sortBy = 'popular';

  ProductProvider() {
    _products = List.from(mockProductsData);
  }

  List<AppProduct> get allProducts => _products;

  List<AppProduct> get filteredProducts {
    var list = _products.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesCategory = _categoryFilter == null ||
          p.category == _categoryFilter ||
          p.subCategory == _categoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();

    switch (_sortBy) {
      case 'price_low':
        list.sort((a, b) => a.pricePerUnit.compareTo(b.pricePerUnit));
        break;
      case 'price_high':
        list.sort((a, b) => b.pricePerUnit.compareTo(a.pricePerUnit));
        break;
      case 'rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }
    return list;
  }

  AppProduct? getById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<AppProduct> getByVendor(String vendorId) =>
      _products.where((p) => p.vendorId == vendorId).toList();

  List<AppProduct> getByCategory(String category) =>
      _products.where((p) => p.category == category || p.subCategory == category).toList();

  List<AppProduct> getSaved(List<String> savedIds) =>
      _products.where((p) => savedIds.contains(p.id)).toList();

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

  void clearFilters() {
    _searchQuery = '';
    _categoryFilter = null;
    _sortBy = 'popular';
    notifyListeners();
  }
}
