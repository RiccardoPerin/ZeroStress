import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String _name = "";

  bool _isLoggedIn = false;
  int _height = 0;
  double _weight = 0.0;
  String get name => _name;
  int get height => _height;
  double get weight => _weight;
  bool get isLoggedIn => _isLoggedIn;

  // Funzione per caricare i dati all'avvio dell'app
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('user_name') ?? "";

    _height = int.tryParse(prefs.getString('user_height') ?? "0") ?? 0;
    _weight = double.tryParse(prefs.getString('user_weight') ?? "0.0") ?? 0.0;

    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    notifyListeners(); // Avvisa l'app che i dati sono pronti
  }

  // Logica di Login
  Future<bool> login(String username, String password, String name, String heightString, String weightString) async {
    if (username == "admin" && password == "1234") {
      _name = name;
      _height = int.tryParse(heightString) ?? 0;
      _weight = double.tryParse(weightString) ?? 0.0;
      _isLoggedIn = true;

      // Salva i dati sul dispositivo
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      await prefs.setString('user_height', _height.toString());
      await prefs.setString('user_weight', _weight.toString());
      await prefs.setBool('is_logged_in', true);

      notifyListeners();
      return true; // Login riuscito
    }
    return false; // Login fallito
  }
}