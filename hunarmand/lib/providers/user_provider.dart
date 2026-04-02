import 'package:flutter/material.dart';
import '../data/mock/mock_user.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  late AppUser _user;

  UserProvider() {
    _user = mockCurrentUser;
  }

  AppUser get user => _user;

  bool isProductSaved(String productId) => _user.savedProducts.contains(productId);
  bool isVendorSaved(String vendorId) => _user.savedVendors.contains(vendorId);

  void toggleSaveProduct(String productId) {
    if (_user.savedProducts.contains(productId)) {
      _user.savedProducts.remove(productId);
    } else {
      _user.savedProducts.add(productId);
    }
    notifyListeners();
  }

  void toggleSaveVendor(String vendorId) {
    if (_user.savedVendors.contains(vendorId)) {
      _user.savedVendors.remove(vendorId);
    } else {
      _user.savedVendors.add(vendorId);
    }
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? email,
    String? buyerType,
    String? province,
    String? city,
  }) {
    if (name != null) _user.name = name;
    if (email != null) _user.email = email;
    if (buyerType != null) _user.buyerType = buyerType;
    if (province != null) _user.province = province;
    if (city != null) _user.city = city;
    notifyListeners();
  }

  void addAddress(UserAddress address) {
    _user.addresses.add(address);
    notifyListeners();
  }

  void toggleNotifications() {
    _user.notifications = !_user.notifications;
    notifyListeners();
  }

  List<UserAddress> get addresses => _user.addresses;
}
