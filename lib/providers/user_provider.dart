import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/impact.dart'; // Per la nuova logica di login

class UserProvider extends ChangeNotifier {
  String _name = "";
  bool _isLoggedIn = false;
  int _height = 0;
  double _weight = 0.0;
  int _age = 0;
  String _gender = "";
  bool _hasDoneOnboarding = false;
  int _time = 0;

  String get name => _name;
  int get height => _height;
  double get weight => _weight;
  int get age => _age;
  String get gender => _gender;
  bool get isLoggedIn => _isLoggedIn;
  bool get hasDoneOnboarding => _hasDoneOnboarding;
  int get time => _time;

  // Funzione per caricare i dati all'avvio dell'app
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('user_name') ?? "";

    _height = int.tryParse(prefs.getString('user_height') ?? "0") ?? 0;
    _weight = double.tryParse(prefs.getString('user_weight') ?? "0.0") ?? 0.0;
    _age = int.tryParse(prefs.getString('user_age') ?? "0") ?? 0;
    _gender = prefs.getString('user_gender') ?? "";
    _time = prefs.getInt('user_time') ?? 0;
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    _hasDoneOnboarding = prefs.getBool('has_done_onboarding') ?? false;

    // Se risultiamo loggati da una sessione precedente, verifichiamo che la
    // sessione sia ancora valida provando a rinnovare i token.
    if (_isLoggedIn) {
      final refresh = prefs.getString('refresh');
      int? statusCode;
      if (refresh != null) {
        try {
          statusCode = await Impact.refreshTokens(refresh);
        } catch (e) {
          statusCode = null;
        }
      }

      if (statusCode != 200) {
        _isLoggedIn = false;
        await prefs.setBool('is_logged_in', false);
      }
    }

    notifyListeners(); // Avvisa l'app che i dati sono pronti
  }

  // Logica per OnBoarding
  Future<String?> completeOnboarding(String name, String heightString, String weightString, String ageString, String gender, double initialTime) async {
    if (name.trim().isEmpty) return "Your name cannot be empty";
    if (gender.isEmpty) return "Select a gender";
    
    int? h = int.tryParse(heightString);
    if (h == null || h <= 0 || h > 250) return "Invalid height";
    
    double? w = double.tryParse(weightString.replaceAll(',', '.'));
    if (w == null || w <= 0 || w > 250) return "Invalid weight";

    int? age = int.tryParse(ageString);
    if (age == null || age <= 0 || age > 116) return "Invalid age";

    _name = name;
    _height = h;
    _weight = w;
    _age = age;
    _gender = gender;
    _hasDoneOnboarding = true;
    _time = initialTime.toInt();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _name);
    await prefs.setString('user_height', _height.toString());
    await prefs.setString('user_weight', _weight.toString());
    await prefs.setString('user_age', _age.toString());
    await prefs.setString('user_gender', _gender);
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        notifyListeners(); // Avvisa la UI di cambiare pagina
        return null; // Nessun errore
      } else {
        // Se lo status code non è 200 (es. 401 Unauthorized)
        return "Wrong sername or password!";
      }
    } catch (e) {
      // Se c'è un problema di rete (es. no internet) catch intercetta l'errore
      return "Server connection error. Try again later.";
    }
  }

  // funzione per CONTROLLARE e AGGIORNARE nome, peso, altezza ed età su settings
  Future<bool> updateProfile(String newName, String heightString, String weightString, String ageString, String gender, double sliderValue) async {
    
    // 1. Pulizia dei dati in ingresso
    String cleanName = newName.trim(); // Rimuove eventuali spazi vuoti prima e dopo
    String cleanWeight = weightString.replaceAll(',', '.'); // Previene errori se l'utente usa la virgola

    // Tentiamo di convertire le stringhe in numeri. Se l'utente ha scritto "ciao" o lasciato vuoto, il risultato sarà 'null'
    int? parsedHeight = int.tryParse(heightString);
    double? parsedWeight = double.tryParse(cleanWeight);
    int? parsedTime = sliderValue.toInt();
    int? parsedAge = int.tryParse(ageString);

    // 2. Controlli di Validazione
    if (cleanName.isEmpty) {
      return false; // Il nome non può essere vuoto
    }
    
    if (parsedHeight == null || parsedHeight <= 0 || parsedHeight > 250) {
      return false; // L'altezza deve essere un numero maggiore di 0
    }
    
    if (parsedWeight == null || parsedWeight <= 0.0 || parsedWeight > 250) {
      return false; // Il peso deve essere un numero maggiore di 0
    }

    if (parsedAge == null || parsedAge <= 0 || parsedAge > 116) {
      return false; // L'età deve essere un numero maggiore di 0
    }

    // Se arriviamo qui, tutti i controlli sono passati! Aggiorniamo lo stato.
    _name = cleanName;
    _height = parsedHeight;
    _weight = parsedWeight;
    _age = parsedAge;
    _time = parsedTime;
    _gender = gender;

    // 4. Salviamo i dati sul dispositivo
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _name);
    await prefs.setString('user_height', _height.toString());
    await prefs.setString('user_weight', _weight.toString());
    await prefs.setString('user_age', _age.toString());
    await prefs.setString('user_gender', _gender);
    await prefs.setInt('user_time', _time);

    // 5. Avvisiamo l'app per aggiornare le schermate
    notifyListeners();
    
    return true; // Salvataggio riuscito!
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    // Non resettiamo tutto, ma solo lo stato di login per mantenere i dati
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
    _age = 0;
    _gender = "";
    _isLoggedIn = false;
    _hasDoneOnboarding = false;
    
    notifyListeners();
  }
}