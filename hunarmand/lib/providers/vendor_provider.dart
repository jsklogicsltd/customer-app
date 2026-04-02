import 'package:flutter/material.dart';
import '../data/mock/mock_vendors.dart';
import '../models/vendor.dart';

class VendorProvider extends ChangeNotifier {
  final List<AppVendor> _vendors = mockVendors;

  List<AppVendor> get allVendors => _vendors;

  AppVendor? getById(String id) {
    try {
      return _vendors.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  List<AppVendor> getSaved(List<String> savedIds) =>
      _vendors.where((v) => savedIds.contains(v.id)).toList();

  List<AppVendor> search(String query) {
    if (query.isEmpty) return _vendors;
    return _vendors.where((v) =>
        v.name.toLowerCase().contains(query.toLowerCase()) ||
        v.specialties.any((s) => s.toLowerCase().contains(query.toLowerCase()))).toList();
  }
}
