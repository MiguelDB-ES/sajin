import 'package:flutter/material.dart';

class AppTheme extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // Notifica os ouvintes sobre a mudança de tema
  }
}
