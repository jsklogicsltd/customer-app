import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/vendor.dart';

class VendorProvider extends ChangeNotifier {
  List<Vendor> vendors = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> fetchVerifiedVendors() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('=== Fetching verified vendors ===');
      final snapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .where('status', isEqualTo: 'verified')
          .get();

      print('Verified vendors found: ${snapshot.docs.length}');

      vendors = snapshot.docs.map((doc) {
        final data = doc.data();
        return Vendor.fromMap(data, doc.id);
      }).toList();

    } catch (e) {
      print('ERROR fetching vendors: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Vendor? getById(String id) {
    try {
      return vendors.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Vendor> getSaved(List<String> ids) {
    return vendors.where((v) => ids.contains(v.id)).toList();
  }

  List<Vendor> search(String query) {
    if (query.isEmpty) return vendors;
    return vendors.where((v) =>
        v.name.toLowerCase().contains(query.toLowerCase())).toList();
  }
}
