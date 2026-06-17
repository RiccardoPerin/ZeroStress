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

    //Creazione della mappa vuota per gestire comunque i null
    final Map<String, double?> weeklyMap = {};
    for (int i = 6; i >= 0; i--) {
      final dateStr = _formatDate(yesterday.subtract(Duration(days: i)));
      weeklyMap[dateStr] = null;
    }
    
    final url = "${Impact.baseUrl}${Impact.dataUrl}resting_heart_rate/patients/${Impact.patient}"
        "/daterange/start_date/$startDate/end_date/$endDate/";

    final response = await _authenticatedGet(url);
    if (response.statusCode == 404){
      return weeklyMap.entries.map((e) => {'date': e.key, 'value': e.value}).toList();
    }
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final rawList = responseBody['data'] as List;

      //Sovrascrivo i valori null dove è presente il dato
      for (var item in rawList) {
        final date = item['date'] as String;
        
        // Controlliamo se il giorno è presente nel nostro range e se ha un valore valido
        if (weeklyMap.containsKey(date) && item['data'].isNotEmpty) {
          weeklyMap[date] = (item['data']['value'] as num).toDouble();
        }
        
      }

      return weeklyMap.entries
          .map<Map<String, dynamic>>((entry) => {
                'date': entry.key,
                'value': entry.value, // Questo sarà double? (quindi può essere null)
              })
          .toList();
    }
    throw Exception("Server error ${response.statusCode} on resting heart rate data");
  }

  // 2. WEEKLY SLEEP DATA --> DURATION
  static Future<List<Map<String, dynamic>>> fetchWeeklySleepData() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final startDate = _formatDate(yesterday.subtract(const Duration(days: 6)));
    final endDate = _formatDate(yesterday);

    //Creazione della mappa vuota per gestire comunque i null
    final Map<String, double?> sleepMap = {};
    for (int i = 6; i >= 0; i--) {
      final dateStr = _formatDate(yesterday.subtract(Duration(days: i)));
      sleepMap[dateStr] = null;
    }
    
    final url = "${Impact.baseUrl}${Impact.dataUrl}sleep/patients/${Impact.patient}"
        "/daterange/start_date/$startDate/end_date/$endDate/";

    final response = await _authenticatedGet(url);
    if (response.statusCode == 404){
      return sleepMap.entries.map((e) => {'date': e.key, 'value': e.value}).toList();
    }
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final rawList = responseBody['data'] as List;

      //Sovrascrivo i valori null dove è presente il dato
      for (var item in rawList) {
        final date = item['date'] as String;
        
        // Controlliamo se il giorno è presente nel nostro range e se ha un valore valido
        if (sleepMap.containsKey(date) && item['data'].isNotEmpty) {
          final duration = item['data']['duration'];
          sleepMap[date] = duration.toDouble();
        }
      }

      return sleepMap.entries
          .map<Map<String, dynamic>>((entry) => {
                'date': entry.key,
                'duration': entry.value, // Questo sarà double? (quindi può essere null), ricordarsi che è in ms
              })
          .toList();
    }
    throw Exception("Server error ${response.statusCode} on resting heart rate data");
  }

  // 3. HEART RATE GIORNALIERO --> LISTA DI MAPPE CON ALL'INTERNO {"date": "2026-05-20","time": "00:00:02","value": 58.0}
  // 4. STEPS GIORNALIERI
  // 5. CALORIES GIORNALIERI
  static Future<List<Map<String, dynamic>>?> fetchDailyData(String dataType, DateTime requestedDate) async {
    final formattedDate = _formatDate(requestedDate);

    final url = "${Impact.baseUrl}${Impact.dataUrl}$dataType/patients/${Impact.patient}/day/$formattedDate/";
    final response = await _authenticatedGet(url);
    if (response.statusCode == 404) return <Map<String, dynamic>>[];
    
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final rawData = responseBody['data'];

      if (rawData is List) return <Map<String, dynamic>>[]; //Gestisce caso in cui orologio non è stato usato

      if (rawData == null) return <Map<String, dynamic>>[];
      
      // Access the inner 'data' map, and then the 'data' list inside it
      final dataContainer = rawData as Map<String, dynamic>;
      if (dataContainer['data'] == null) return <Map<String, dynamic>>[];
      
      final rawMeasurements = dataContainer['data'] as List;
      //final dateStr = dataContainer['date'] as String; // "2026-05-20" //Capire se serve avere la data

      // Transform the list, keeping null values intact
      return rawMeasurements.map<Map<String, dynamic>>((item) {
        final rawValue = item['value'];
        double? doubleValue;

        //Controlla per fare il cast corretto siccome il value di Calories è stringa
        if (rawValue != null){
          if (rawValue is num) {
            doubleValue = rawValue.toDouble();
          }
          else if (rawValue is String) {
            doubleValue = double.tryParse(rawValue);
          }
        }

        return {
          //'date': dateStr,
          'time': item['time'] as String,
          'value': doubleValue, // This can safely be null
        };
      }).toList();
    }
    
    throw Exception("Server error ${response.statusCode} on heart rate intraday data");
  }

  // 6. DAILY EXERCISE, WILL RETURN TIME OF START AND TIME OF END
  static Future<List<Map<String, dynamic>>?> fetchDailyExcersiseData(DateTime requestedDate) async {
    final formattedDate = _formatDate(requestedDate);

    final url = "${Impact.baseUrl}${Impact.dataUrl}exercise/patients/${Impact.patient}/day/$formattedDate/";
    final response = await _authenticatedGet(url);
    if (response.statusCode == 404) return [];
    
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final rawData = responseBody['data'];

      if (rawData is List) return <Map<String, dynamic>>[];
      if (rawData == null) return <Map<String, dynamic>>[];

      // Access the inner 'data' map, and then the 'data' list inside it
      final dataContainer = rawData as Map<String, dynamic>;
      if (dataContainer['data'] == null) return <Map<String, dynamic>>[];
      
      final rawMeasurements = dataContainer['data'] as List;
      final dateStr = dataContainer['date'] as String; // "2026-05-20" //Capire se serve avere la data

      // Transform the list, keeping null values intact
      return rawMeasurements.map<Map<String, dynamic>>((item) {
        final String startTimeStr = item['time'];
        final double durationMs = item['duration'];

        String endTimeStr = startTimeStr; //In caso di errore allora non lo considera

        try {
          final timeParts = startTimeStr.split(':');
          if (timeParts.length == 3) {
            // Creiamo un DateTime fittizio usando la data dell'esercizio e l'orario di inizio
            final dateParts = dateStr.split('-');
            final startDateTime = DateTime(
              int.parse(dateParts[0]), // Anno
              int.parse(dateParts[1]), // Mese
              int.parse(dateParts[2]), // Giorno
              int.parse(timeParts[0]), // Ore
              int.parse(timeParts[1]), // Minuti
              int.parse(timeParts[2]), // Secondi
            );

            // Sommiamo la durata in millisecondi
            final endDateTime = startDateTime.add(Duration(milliseconds: durationMs.toInt()));

            // Formattiamo l'orario di fine come stringa "HH:mm:ss" aggiungendo lo zero iniziale se necessario
            final hours = endDateTime.hour.toString().padLeft(2, '0');
            final minutes = endDateTime.minute.toString().padLeft(2, '0');
            final seconds = endDateTime.second.toString().padLeft(2, '0');
            
            endTimeStr = "$hours:$minutes:$seconds";
          }
        } catch (e) {
          print("Error parsing exercise time: $e");
        }

        return {
          'date': dateStr,
          'time_start': startTimeStr,
          'time_end': endTimeStr,
        };
      }).toList();
    }
    
    throw Exception("Server error ${response.statusCode} on exercise data");
  }




  // ─────────────────────────────────────────────────────────────────────────
  // FUNZIONE PER GESTIONE FORMATO DATA
  // ─────────────────────────────────────────────────────────────────────────

  static String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  // DateTime.now() restituisce yyyy-MM-gg hh:mm:ss.(6 cifre millisecondi) → gli diciamo di pescare solo anno mese e giorno
  // OSS: dobbiamo fare pad perchè ad es. a maggio d.month è 5 e non 05 !!!
}

