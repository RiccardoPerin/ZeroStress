import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
 
class Impact{
  
  static final patient = "Jpefaq6m58"; 

  static final baseUrl = "https://impact.dei.unipd.it/bwthw/";
  static final gateUrl = "gate/v1/";
  static final dataUrl = "data/v1/";


  static Future<int> getTokens(String username, String password) async {
    // 1. create url
    final url = Impact.baseUrl + Impact.gateUrl + 'token/';
    final formattedUrl = Uri.parse(url);
    // 2. call the method
    final body = {'username' : username, 'password' : password};
    final response = await http.post(formattedUrl, body: body,);

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final sp = await SharedPreferences.getInstance();
      await sp.setString("access", responseBody["access"]);
      await sp.setString("refresh", responseBody["refresh"]);
    }

    return response.statusCode; // per verificare che abbia funzionato
  }

  static Future<int> refreshTokens(String refresh) async {

    // 1. create url
    final url = Impact.baseUrl + Impact.gateUrl + 'refresh/';
    final formattedUrl = Uri.parse(url);
    // 2. call the method
    final body = {"refresh" : refresh};
    final response = await http.post(formattedUrl, body: body,);

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final sp = await SharedPreferences.getInstance();
      await sp.setString("access", responseBody["access"]);
      await sp.setString("refresh", responseBody["refresh"]);
    } 

    return response.statusCode; // per verificare che abbia funzionato
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RICHIESTA AUTENTICATA
  // ─────────────────────────────────────────────────────────────────────────

  static Future<http.Response> _authenticatedGet(String url) async {
    final formattedUrl = Uri.parse(url);

    final sp = await SharedPreferences.getInstance();
    String? access = sp.getString("access");
    String? refresh = sp.getString("refresh");

    if (access == null) throw Exception("Not authenticated"); // controlla che tu sia autenticato, credo si possa togliere...

    var response = await http.get(
      formattedUrl,
      headers: {"Authorization": "Bearer $access"},
    );

    // se il token di accesso è scaduto MA abbiamo il token di refresh → chiama _refreshTokens e li sovrascrive
    if (response.statusCode == 401 && refresh != null) { 
      final refreshStatus = await refreshTokens(refresh);
      if (refreshStatus == 200) { // → Se refresh ha funzionato (ovvero token 'refresh' non era scaduto) allora esegue la richiesta dei dati
        final newAccess = sp.getString("access")!;
        response = await http.get(
          Uri.parse(url),
          headers: {"Authorization": "Bearer $newAccess"},
        );
      } else {
        throw Exception("Session expired. Please login again.");
      }
    }
    return response; // restituisco tutta la risposta, se la chiamata non ha funzioanto manda l'eccezione e non arriva mai qua
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RICHIESTE DATI EFFETTIVE
  // ─────────────────────────────────────────────────────────────────────────

  // 1. RHR Settimanale

  static Future<List<Map<String, dynamic>>> fetchWeeklyRestingHeartRate() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final startDate = _formatDate(yesterday.subtract(const Duration(days: 6)));
    final endDate = _formatDate(yesterday);

    final url = "${Impact.baseUrl}${Impact.dataUrl}resting_heart_rate/patients/${Impact.patient}"
        "/daterange/start_date/$startDate/end_date/$endDate/";

    final response = await _authenticatedGet(url);
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final rawList = responseBody['data'] as List;

      // TRASFORMAZIONE: Semplifichiamo la struttura della lista
      return rawList.map<Map<String, dynamic>>((item) {
        return {
          'date': item['date'] as String,
          // Usiamo 'as num' e '.toDouble()' per metterci al sicuro da oscillazioni dei tipi del server
          'value': (item['data']['value'] as num).toDouble(), 
        };
      }).toList();
    }
    throw Exception("Server error ${response.statusCode} on resting heart rate data");
  }







  // ─────────────────────────────────────────────────────────────────────────
  // FUNZIONE PER GESTIONE FORMATO DATA
  // ─────────────────────────────────────────────────────────────────────────

  static String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  // DateTime.now() restituisce yyyy-MM-gg hh:mm:ss.(6 cifre millisecondi) → gli diciamo di pescare solo anno mese e giorno
  // OSS: dobbiamo fare pad perchè ad es. a maggio d.month è 5 e non 05 !!!
}

