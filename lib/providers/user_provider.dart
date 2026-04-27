//import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String _name = "";
  bool _isLoggedIn = false;
  int _height = 0;
  double _weight = 0.0;
  bool _hasDoneOnboarding = false;

  String get name => _name;
  int get height => _height;
  double get weight => _weight;
  bool get isLoggedIn => _isLoggedIn;
  bool get hasDoneOnboarding => _hasDoneOnboarding;

  // Funzione per caricare i dati all'avvio dell'app
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('user_name') ?? "";

    _height = int.tryParse(prefs.getString('user_height') ?? "0") ?? 0;
    _weight = double.tryParse(prefs.getString('user_weight') ?? "0.0") ?? 0.0;

    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    _hasDoneOnboarding = prefs.getBool('has_done_onboarding') ?? false;
    notifyListeners(); // Avvisa l'app che i dati sono pronti
  }

  // Logica per OnBoarding
  Future<String?> completeOnboarding(String name, String heightString, String weightString) async {
    if (name.trim().isEmpty) return "Your name cannot be empty";
    
    int? h = int.tryParse(heightString);
    if (h == null || h <= 0) return "Invalid height";
    
    double? w = double.tryParse(weightString.replaceAll(',', '.'));
    if (w == null || w <= 0) return "Invalid weight";

    _name = name;
    _height = h;
    _weight = w;
    _hasDoneOnboarding = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _name);
    await prefs.setString('user_height', _height.toString());
    await prefs.setString('user_weight', _weight.toString());
    await prefs.setBool('has_done_onboarding', true);

    notifyListeners();
    return null;

  }

  // Logica di Login
  Future<String?> login(String username, String password) async {
    if (username == "admin" && password == "1234") {
      _isLoggedIn = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      notifyListeners();
      return null; // No errors
    } 
    else {
      return "Wrong Username or Password!";
    }
  }

  // funzione per CONTROLLARE e AGGIORNARE nome, peso, altezza su settings
  Future<bool> updateProfile(String newName, String heightString, String weightString) async {
    
    // 1. Pulizia dei dati in ingresso
    String cleanName = newName.trim(); // Rimuove eventuali spazi vuoti prima e dopo
    String cleanWeight = weightString.replaceAll(',', '.'); // Previene errori se l'utente usa la virgola

    // Tentiamo di convertire le stringhe in numeri. Se l'utente ha scritto "ciao" o lasciato vuoto, il risultato sarà 'null'
    int? parsedHeight = int.tryParse(heightString);
    double? parsedWeight = double.tryParse(cleanWeight);

    // 2. Controlli di Validazione
    if (cleanName.isEmpty) {
      return false; // Il nome non può essere vuoto
    }
    
    if (parsedHeight == null || parsedHeight <= 0) {
      return false; // L'altezza deve essere un numero maggiore di 0
    }
    
    if (parsedWeight == null || parsedWeight <= 0.0) {
      return false; // Il peso deve essere un numero maggiore di 0
    }

    // Se arriviamo qui, tutti i controlli sono passati! Aggiorniamo lo stato.
    _name = cleanName;
    _height = parsedHeight;
    _weight = parsedWeight;

    // 4. Salviamo i dati sul dispositivo
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _name);
    await prefs.setString('user_height', _height.toString());
    await prefs.setString('user_weight', _weight.toString());

    // 5. Avvisiamo l'app per aggiornare le schermate
    notifyListeners();
    
    return true; // Salvataggio riuscito!
  }
}