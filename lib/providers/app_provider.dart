import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  String _language = 'en'; // 'en' | 'ur'
  bool _isDarkMode = false;
  int _currentNavIndex = 0;

  String get language => _language;
  bool get isDarkMode => _isDarkMode;
  bool get isUrdu => _language == 'ur';
  int get currentNavIndex => _currentNavIndex;

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }
}
