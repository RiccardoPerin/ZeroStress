import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ZeroStress/services/impact.dart';

class HealthDataProvider extends ChangeNotifier {

  bool _hasHealthData = false;

  // ── RHR Settimanale ────────────────────────────────────────────────────────
  List<double?> _weeklyRHR = List.filled(7, null);
  double _baselineRHR = 0.0;
  int _age = 0;
  double _stressLevel = 0.0;

  // ── Streak ─────────────────────────────────────────────────────────────────
  int _currentStreak = 0;
  List<bool> _last7DaysCompleted = List.filled(7, false);

  // ── Loading / Error ────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get hasHealthData => _hasHealthData;
  List<double?> get weeklyRHR => _weeklyRHR;
  double get baselineRHR => _baselineRHR;
  int get currentStreak => _currentStreak;
  List<bool> get last7DaysCompleted => _last7DaysCompleted;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get age => _age;
  double get stressLevel => _stressLevel;

  // ─────────────────────────────────────────────────────────────────────────
  // FETCH PRINCIPALE
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchAllData() async {
    _isLoading = true;
    _errorMessage = null;
    await _loadStreak();
    notifyListeners();

    try {
      final weeklyRHR = await Impact.fetchWeeklyRestingHeartRate();
      final weeklySleep = await Impact.fetchWeeklySleepData();
      final dailyHR = await Impact.fetchDailyData("heart_rate", DateTime.now().subtract(const Duration(days: 1)));
      final dailySteps = await Impact.fetchDailyData("steps", DateTime.now().subtract(const Duration(days: 1)));
      final dailyCalories = await Impact.fetchDailyData("calories", DateTime.now().subtract(const Duration(days: 1)));
      final dailyExercise = await Impact.fetchDailyExcersiseData(DateTime.now().subtract(const Duration(days: 1)));

      print('Weekly RHR:');
      print(weeklyRHR);
      print('Weekly Sleep:');
      print(weeklySleep);
      print('Daily exercise:');
      print(dailyExercise);
      print('Daily steps:');
      print(dailySteps);
      print('Daily calories:');
      print(dailyCalories);
      print('Daily Heart rate:');
      print(dailyHR);


      _computeWeeklyRHR(weeklyRHR);
      _computeStress(
        recentHeartRate: dailyHR,
        recentSteps: dailySteps,
        recentCalories: dailyCalories,
        activeExercises: dailyExercise,
        weeklySleep: weeklySleep,
      );

      _hasHealthData = true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CALCOLO RHR SETTIMANALE
  // ─────────────────────────────────────────────────────────────────────────

  void _computeWeeklyRHR(List<Map<String, dynamic>> data) {
    final List<double?> rhr = List.filled(7, null);

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final startDay = DateTime(yesterday.year, yesterday.month, yesterday.day)
        .subtract(const Duration(days: 6));

    for (final entry in data) {
      DateTime? date;
      double? value;

      try {
        final dateStr = entry['date'] as String? ?? entry['day'] as String?;
        if (dateStr != null) date = DateTime.parse(dateStr);

        value = (entry['resting_heart_rate'] ??
                entry['rhr'] ??
                entry['value'] ??
                entry['bpm'])
            ?.toDouble();
      } catch (_) {}

      if (date != null && value != null) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        final idx = dateOnly.difference(startDay).inDays;
        if (idx >= 0 && idx < 7) rhr[idx] = value;
      }
    }

    _weeklyRHR = rhr;

    final available = rhr.whereType<double>().toList();
    if (available.isNotEmpty) {
      _baselineRHR = available.reduce((a, b) => a + b) / available.length;
    }

    if (_baselineRHR == 0.0) _baselineRHR = 62.0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CALCOLO STRESS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _computeStress({
    required List<Map<String, dynamic>>? recentHeartRate,
    required List<Map<String, dynamic>>? recentSteps,
    required List<Map<String, dynamic>>? recentCalories,
    required List<Map<String, dynamic>>? activeExercises,
    required List<Map<String, dynamic>>? weeklySleep,
  }) async {
    const double sleepDurationMock = 450.0; //Dati per l'imputazione in caso manchino (7.5 ore in minuti)
    //const double sleepEfficiencyMock = 85.0;
    const double basalCaloriesPerMinute = 1.28;

    const double maxDailyStressPointsCeiling = 18000.0; //Valore da cambiare con test. Se a fine giornata stress è alto allora alzare questo

    final sp = await SharedPreferences.getInstance();
    _age = int.tryParse(sp.getString('user_age') ?? "30") ?? 25;
    double maxHR = 208 - 0.7 * _age;

    double heartRateReserve = maxHR - _baselineRHR;  
    if (heartRateReserve <= 0) heartRateReserve = 100.0; //Caso in cui siamo ben sopra il massimo

    // ── 3. ALLINEAMENTO TEMPORALE (RAGGRUPPAMENTO PER MINUTO 'HH:mm') ──
    // Creiamo dizionari veloci per leggere passi e calorie al volo
    Map<String, double> stepsByMinute = {};
    if (recentSteps != null) {
      for (var s in recentSteps) {
        String timeStr = s['time'] as String? ?? "00:00:00";
        String minuteKey = timeStr.length >= 5 ? timeStr.substring(0, 5) : "00:00";
        stepsByMinute[minuteKey] = (stepsByMinute[minuteKey] ?? 0.0) + (s['value'] as num? ?? 0).toDouble();
      }
    }

    Map<String, double> caloriesByMinute = {};
    if (recentCalories != null) {
      for (var c in recentCalories) {
        String timeStr = c['time'] as String? ?? "00:00:00";
        String minuteKey = timeStr.length >= 5 ? timeStr.substring(0, 5) : "00:00";
        caloriesByMinute[minuteKey] = (caloriesByMinute[minuteKey] ?? 0.0) + (c['value'] as num? ?? 0).toDouble();
      }
    }

    // Raggruppiamo i battiti cardiaci per minuto per farne la media
    Map<String, List<double>> hrByMinute = {};
    if (recentHeartRate != null) {
      for (var hr in recentHeartRate) {
        String timeStr = hr['time'] as String? ?? "00:00:00";
        String minuteKey = timeStr.length >= 5 ? timeStr.substring(0, 5) : "00:00";
        double val = (hr['value'] as num? ?? 0).toDouble();
        
        if (val > 0) {
          hrByMinute.putIfAbsent(minuteKey, () => []).add(val);
        }
      }
    }

    // ── 4. CALCOLO CUMULATIVO SUL "NASTRO TRASPORTATORE" ──
    double cumulativeStressPoints = 0.0;

    // Analizziamo ogni singolo minuto in cui abbiamo un dato del cuore
    for (String minuteKey in hrByMinute.keys) {
      // Media dei battiti in quel minuto (può essere un campione solo o 15, non importa, facciamo la media)
      List<double> hrSamples = hrByMinute[minuteKey]!;
      double avgHr = hrSamples.reduce((a, b) => a + b) / hrSamples.length;

      // Filtro 1: È in allenamento dichiarato?
      bool isExercising = false;
      if (activeExercises != null) {
        for (var exe in activeExercises) {
          String start = exe['time_start'] as String? ?? "00:00:00";
          String end = exe['time_end'] as String? ?? "00:00:00";
          // Creiamo una stringa comparabile es: "14:30:00"
          String currentFullTime = "$minuteKey:00"; 
          if (currentFullTime.compareTo(start) >= 0 && currentFullTime.compareTo(end) <= 0) {
            isExercising = true;
            break;
          }
        }
      }
      if (isExercising) continue; // Salta questo minuto, lo stress è fisico

      // Filtro 2: Si sta muovendo?
      double stepsInMin = stepsByMinute[minuteKey] ?? 0.0;
      double calsInMin = caloriesByMinute[minuteKey] ?? basalCaloriesPerMinute;
      
      // Se fa più di 15 passi o brucia più del triplo del BMR in un minuto, è in movimento
      if (stepsInMin > 15 || calsInMin > (basalCaloriesPerMinute * 3.0)) {
        continue; // Salta, il battito alto è giustificato
      }

      // ── LOGICA DI ESTRAZIONE STRESS ──
      // Se è fermo, ma il cuore batte forte
      if (avgHr > _baselineRHR) {
        double hrElevation = avgHr - _baselineRHR;
        
        // Quanta riserva cardiaca sta usando da seduto? (0.0 a 1.0+)
        double intensity = hrElevation / heartRateReserve; 
        
        // Assegniamo punti. Più l'intensità è alta, più i punti si moltiplicano in modo esponenziale
        // Se intensity è 0.2 (20%), aggiunge punti. 
        double pointsPerMinute = (intensity * 100) * 1.5; 
        cumulativeStressPoints += pointsPerMinute;
      }
    }

    // ── 5. MAPPING DA PUNTI GREZZI A PERCENTUALE (0-100) ──
    double rawStressLevel = (cumulativeStressPoints / maxDailyStressPointsCeiling) * 100.0;

    // ── 6. L'AMPLIFICATORE (SONNO DELLA NOTTE) ──
    double avgSleepDuration = sleepDurationMock;
    if (weeklySleep != null && weeklySleep.isNotEmpty) {
      // Estraiamo la durata dell'ultima notte disponibile
      final lastNight = weeklySleep.last['data'];
      if (lastNight != null && lastNight is! List) {
        double durationMs = (lastNight['duration'] as num? ?? 0).toDouble();
        if (durationMs > 0) {
          avgSleepDuration = durationMs / 60000; // in minuti
        }
      }
    }

    double sleepMultiplier = 1.0;
    double sleepDeficit = sleepDurationMock - avgSleepDuration; // Target 450 min
    if (sleepDeficit > 0) {
      // Fino a +35% di penalità se si dorme pochissimo
      sleepMultiplier += (sleepDeficit / sleepDurationMock) * 0.35; 
    }

    double finalStress = rawStressLevel * sleepMultiplier;

    // ── 7. L'ANTIDOTO (RESPIRAZIONE) ──
    final int breathingMinutesToday = await getTodayBreathingMinutes();
    
    // Ogni minuto di respiro toglie 4 punti percentuali netti dallo stress accumulato
    double stressReduction = breathingMinutesToday * 4.0; 
    finalStress -= stressReduction;

    // Salvataggio finale
    _stressLevel = double.parse(finalStress.clamp(0.0, 100.0).toStringAsFixed(1));
    
    // Log per il debug
    print("-------------------------------------------------");
    print("Calcolo Stress Cumulativo Completato:");
    print("Baseline RHR: $_baselineRHR | MaxHR: $maxHR");
    print("Punti Stress Accumulati: ${cumulativeStressPoints.toStringAsFixed(0)}");
    print("Moltiplicatore Sonno: ${sleepMultiplier.toStringAsFixed(2)}");
    print("Riduzione Respirazione: -$stressReduction%");
    print("Stress Finale: $stressLevel%");
    print("-------------------------------------------------");

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STREAK
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadStreak() async {
    final sp = await SharedPreferences.getInstance();
    _currentStreak = sp.getInt('streak_count') ?? 0;

    final today = DateTime.now();
    final todayDone = sp.getBool('streak_day_${_dateKey(today)}') ?? false;
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayDone = sp.getBool('streak_day_${_dateKey(yesterday)}') ?? false;
    
    if (!yesterdayDone && !todayDone) {
      _currentStreak = 0;
      await sp.setInt('streak_count', _currentStreak);
    }

    // I pallini mostrano solo la settimana corrente (Lun=0 … Dom=6):
    // si azzerano visivamente ogni lunedì, anche se lo streak continua a contare
    // weekday assegna 1=Lunedì, 2=Martedì e così via, sottraendo da oggi il numero meno 1 arrivo sempre a lunedì
    final mondayOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
    final List<bool> completed = List.filled(7, false);
    for (int i = 0; i < 7; i++) {
      final day = mondayOfThisWeek.add(Duration(days: i));
      completed[i] = sp.getBool('streak_day_${_dateKey(day)}') ?? false;
    }
    _last7DaysCompleted = completed;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RESPIRAZIONE
  // ─────────────────────────────────────────────────────────────────────────

  Future<int> getTodayBreathingMinutes() async {
    final sp = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    return sp.getInt('breathing_minutes_$today') ?? 0;
  }

  Future<void> addBreathingMinutes(int minutes, int goalMinutes) async {
    final sp = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    final key = 'breathing_minutes_$today';

    final current = sp.getInt(key) ?? 0;
    final updated = current + minutes;
    await sp.setInt(key, updated);

    if (updated >= goalMinutes) {
      //final todayDone = sp.setBool('todayDone', true);
      await markTodayAsCompleted();
    }

    notifyListeners();
  }

  Future<void> markTodayAsCompleted() async {
    final sp = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key = 'streak_day_${_dateKey(today)}';

    if (sp.getBool(key) == true) return;

    await sp.setBool(key, true);

    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayDone = sp.getBool('streak_day_${_dateKey(yesterday)}') ?? false;
    if (yesterdayDone || _currentStreak==0) {
      _currentStreak++;
    }
    else {
      _currentStreak = 1;
    }

    await sp.setInt('streak_count', _currentStreak);
    await _loadStreak();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FUNZIONE PER GESTIONE FORMATO DATA
  // ─────────────────────────────────────────────────────────────────────────

  String _dateKey(DateTime d) =>
      "${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}";
  // DateTime.now() restituisce yyyy-MM-gg hh:mm:ss.(6 cifre millisecondi) → gli diciamo di pescare solo anno mese e giorno
  // OSS: dobbiamo fare pad perchè ad es. a maggio d.month è 5 e non 05 !!!
}
