import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Impact{
  
  static final patient = "Jpefaq6m58"; 

  static final baseUrl = "https://impact.dei.unipd.it/bwthw/";
  static final gateUrl = "gate/v1/";
  static final dataUrl = "data/v1/";

  //Function to get the tokens initially
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

  //Function to refresh the tokens when needed
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


  //Function to do the get queries and check if the authentication is okay
  static Future<http.Response> _authenticatedGet(String url) async {
    final formattedUrl = Uri.parse(url);

    final sp = await SharedPreferences.getInstance();
    String? access = sp.getString("access");
    String? refresh = sp.getString("refresh");

    if (access == null) throw Exception("Not authenticated");

    var response = await http.get(
      formattedUrl,
      headers: {"Authorization": "Bearer $access"},
    );

    // Token scaduto → refresh e riprova
    if (response.statusCode == 401 && refresh != null) {
      final refreshStatus = await refreshTokens(refresh);
      if (refreshStatus == 200) { //Se refresh ha funzionato
        final newAccess = sp.getString("access")!;
        response = await http.get(
          Uri.parse(url),
          headers: {"Authorization": "Bearer $newAccess"},
        );
      } else {
        throw Exception("Session expired. Please login again.");
      }
    }
    return response;
  }


  // Generic function to fetch data daily --> DA SISTEMARE L'IDEA
  static Future<Map<String, dynamic>?> _fetchDataDay(String endpoint, String date) async {
    final url = "${Impact.baseUrl}${Impact.dataUrl}$endpoint/patients/${Impact.patient}/day/$date/";

    final response = await _authenticatedGet(url);

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      
      // 1. Entriamo nel primo livello di 'data'
      final rootData = responseBody['data'];
      
      if (rootData != null) {
        // 2. Estraiamo la data (String)
        final String extractedDate = rootData['date'];
        
        // 3. Entriamo nel secondo livello di 'data' per prendere il 'value' (double)
        // Usiamo 'as num' e poi '.toDouble()' per evitare crash se il server restituisce un intero (es. 56 invece di 56.39)
        final double extractedValue = (rootData['data']['value'] as num).toDouble();
        
        // 4. Ritorniamo i due dati impacchettati in una mappa
        return {
          'date': extractedDate,
          'value': extractedValue,
        };
      }
      return null;
    }
  }

  // Fetch daily data using the generic function --> DA SISTEMARE L'IDEA
  static Future<Map<String, dynamic>?> getHeartRate(String date) => _fetchDataDay('heart_rate', date);
  static Future<Map<String,dynamic>?> getRestingHeartRate(String date) => _fetchDataDay('resting_heart_rate', date);
  static Future<Map<String,dynamic>?> getSteps(String date) => _fetchDataDay('steps', date);
  static Future<Map<String,dynamic>?> getCalories(String date) => _fetchDataDay('calories', date);

  //Function to get the RHR of the whole week, which will be used to create the chart in the homepage
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

  //Function to get the sleep data from last night --> gets time, efficiency and date
  static Future<Map<String, dynamic>?> fetchLastNightSleep() async {
    final yesterday = _formatDate(DateTime.now().subtract(const Duration(days: 1)));
    final url = "${Impact.baseUrl}${Impact.dataUrl}sleep/patients/${Impact.patient}/day/$yesterday/";

    final response = await _authenticatedGet(url);
    
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final rootData = responseBody['data'];

      if (rootData == null) return null;

      final innerData = rootData['data'];

      // GESTIONE EDGE CASE: Se innerData è una lista (es. []), significa che non ci sono dati di sonno
      if (innerData is List) {
        print("Nessun dato di sonno registrato per la giornata di ieri.");
        return null; 
      }

      // Se è una mappa, estraiamo i dati che ti interessano
      final String date = rootData['date'] as String;
      final double duration = (innerData['duration'] as num).toDouble();
      final int efficiency = (innerData['efficiency'] as num).toInt();

      // Ritorniamo una mappa semplice e "piatta"
      return {
        'date': date,
        'duration': duration, // in millisecondi
        'efficiency': efficiency,
      };
    }
    
    throw Exception("Server error ${response.statusCode} on sleep data");
  }

  //Forse si può togliere
  static String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

}

