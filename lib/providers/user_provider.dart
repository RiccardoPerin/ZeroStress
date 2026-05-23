//import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/impact.dart'; // Per la nuova logica di login

class UserProvider extends ChangeNotifier {
  String _name = "";
  bool _isLoggedIn = false;
  int _height = 0;
  double _weight = 0.0;
  bool _hasDoneOnboarding = false;
  int _time = 0;

  String get name => _name;
  int get height => _height;
  double get weight => _weight;
  bool get isLoggedIn => _isLoggedIn;
  bool get hasDoneOnboarding => _hasDoneOnboarding;
  int get time => _time;

  // Funzione per caricare i dati all'avvio dell'app
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('user_name') ?? "";

    _height = int.tryParse(prefs.getString('user_height') ?? "0") ?? 0;
    _weight = double.tryParse(prefs.getString('user_weight') ?? "0.0") ?? 0.0;
    _time = prefs.getInt('user_time') ?? 0;
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    _hasDoneOnboarding = prefs.getBool('has_done_onboarding') ?? false;
    notifyListeners(); // Avvisa l'app che i dati sono pronti
  }

  // Logica per OnBoarding
  Future<String?> completeOnboarding(String name, String heightString, String weightString, double initialTime) async {
    if (name.trim().isEmpty) return "Your name cannot be empty";
    
    int? h = int.tryParse(heightString);
    if (h == null || h <= 0) return "Invalid height";
    
    double? w = double.tryParse(weightString.replaceAll(',', '.'));
    if (w == null || w <= 0) return "Invalid weight";

    _name = name;
    _height = h;
    _weight = w;
    _hasDoneOnboarding = true;
    _time = initialTime.toInt();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _name);
    await prefs.setString('user_height', _height.toString());
    await prefs.setString('user_weight', _weight.toString());
    await prefs.setBool('has_done_onboarding', true);
    await prefs.setInt('user_time', _time);

    notifyListeners();
    return null;

  }

  Future<String?> login(String username, String password) async {
    try {
      // Chiamiamo il metodo statico della tua classe Impact
      int statusCode = await Impact.getTokens(username, password);

      if (statusCode == 200) {
        // I token sono già stati salvati da impact.dart
        _isLoggedIn = true;
        notifyListeners(); // Avvisa la UI di cambiare pagina
        return null; // Nessun errore
      } else {
        // Se lo status code non è 200 (es. 401 Unauthorized)
        return "Username o password errati!";
      }
    } catch (e) {
      // Se c'è un problema di rete (es. no internet) catch intercetta l'errore
      return "Errore di connessione al server. Riprova.";
    }
  }

  // funzione per CONTROLLARE e AGGIORNARE nome, peso, altezza su settings
  Future<bool> updateProfile(String newName, String heightString, String weightString, double sliderValue) async {
    
    // 1. Pulizia dei dati in ingresso
    String cleanName = newName.trim(); // Rimuove eventuali spazi vuoti prima e dopo
    String cleanWeight = weightString.replaceAll(',', '.'); // Previene errori se l'utente usa la virgola

    // Tentiamo di convertire le stringhe in numeri. Se l'utente ha scritto "ciao" o lasciato vuoto, il risultato sarà 'null'
    int? parsedHeight = int.tryParse(heightString);
    double? parsedWeight = double.tryParse(cleanWeight);
    int? parsedTime = sliderValue.toInt();

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
    _time = parsedTime;

    // 4. Salviamo i dati sul dispositivo
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _name);
    await prefs.setString('user_height', _height.toString());
    await prefs.setString('user_weight', _weight.toString());
    await prefs.setInt('user_time', _time);

    // 5. Avvisiamo l'app per aggiornare le schermate
    notifyListeners();
    
    return true; // Salvataggio riuscito!
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    // Non resettiamo tutto, ma solo lo stato di login se vuoi mantenere i dati
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    notifyListeners();
  }

  Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Elimina tutto ciò che è stato salvato in SharedPreferences
    
    // Resetta le variabili locali
    _name = "";
    _height = 0;
    _weight = 0.0;
    _time = 0;
    _isLoggedIn = false;
    _hasDoneOnboarding = false;
    
    notifyListeners();
  }
}