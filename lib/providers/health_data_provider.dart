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
  double _recoveryLevel = 0.0;

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
  double get recoveryLevel => _recoveryLevel;

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
      _computeStressAndRecovery(
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
  // CALCOLO STRESS e RECOVERY
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _computeStressAndRecovery({
    required List<Map<String, dynamic>>? recentHeartRate,
    required List<Map<String, dynamic>>? recentSteps,
    required List<Map<String, dynamic>>? recentCalories,
    required List<Map<String, dynamic>>? activeExercises,
    required List<Map<String, dynamic>>? weeklySleep,
  }) async {
    // ── 1. COSTANTI E TEMPO DINAMICO TRASLATO (IERI SU OGGI) ──
    const double targetSleepDuration = 450.0; // 7.5 ore in minuti
    const double basalCaloriesPerMinute = 1.28;
    const double maxPointsPerMinute = 1.5; 
    const double maxDrainPerMinute = 0.35;
    const double maxMentalElevation = 35.0; // Soglia psicogena emotiva

    // Allineamento temporale al minuto attuale
    final now = DateTime.now();
    int minutesPassedToday = (now.hour * 60) + now.minute;
    if (minutesPassedToday == 0) minutesPassedToday = 1;

    final String timeLimitStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";

    // ── 2. PROFILO ANAGRAFICO E BASELINE BIOLOGICA ──
    final sp = await SharedPreferences.getInstance();
    int age = int.tryParse(sp.getString('user_age') ?? "30") ?? 30;
    
    double maxHR = 208.0 - (0.7 * age);
    double heartRateReserve = maxHR - _baselineRHR;
    if (heartRateReserve <= 0) heartRateReserve = 100.0; 

    // ── 3. RICARICA NOTTURNA E CARICO ALLOSTATICO SETTIMANALE ──
    // A. Recovery Iniziale (Initial Battery da Sonno)
    double actualSleepDuration = targetSleepDuration;
    if (weeklySleep != null && weeklySleep.isNotEmpty) {
      final lastNight = weeklySleep.last['data'];
      if (lastNight != null && lastNight is! List) {
        double durationMs = (lastNight['duration'] as num? ?? 0).toDouble();
        if (durationMs > 0) actualSleepDuration = durationMs / 60000;
      }
    }
    double sleepRatio = (actualSleepDuration / targetSleepDuration).clamp(0.0, 1.0);
    double initialMentalBattery = 50.0 + (sleepRatio * 50.0); // Parte tra 50% e 100%

    // B. Stress Settimanale Accumulato (Trend RHR)
    double weeklyStressPenalty = 0.0;
    List<double> validWeeklyRHR = _weeklyRHR.whereType<double>().toList();
    if (validWeeklyRHR.length >= 2 && _baselineRHR > 0) {
      double latestRHR = validWeeklyRHR.last;
      if (latestRHR > _baselineRHR + 2.0) {
        double rhrElevation = latestRHR - _baselineRHR;
        weeklyStressPenalty = (rhrElevation * 5.0).clamp(0.0, 30.0); 
      }
    }

    // ── 4. MAPPE TEMPORALI DI ALLINEAMENTO (FILTRATE FINO AD ORA) ──
    Map<String, double> stepsByMinute = {};
    if (recentSteps != null) {
      for (var s in recentSteps) {
        String timeStr = s['time'] as String? ?? "00:00:00";
        if (timeStr.compareTo(timeLimitStr) > 0) continue;
        String minuteKey = timeStr.length >= 5 ? timeStr.substring(0, 5) : "00:00";
        stepsByMinute[minuteKey] = (stepsByMinute[minuteKey] ?? 0.0) + (s['value'] as num? ?? 0).toDouble();
      }
    }

    Map<String, double> caloriesByMinute = {};
    if (recentCalories != null) {
      for (var c in recentCalories) {
        String timeStr = c['time'] as String? ?? "00:00:00";
        if (timeStr.compareTo(timeLimitStr) > 0) continue;
        String minuteKey = timeStr.length >= 5 ? timeStr.substring(0, 5) : "00:00";
        caloriesByMinute[minuteKey] = (caloriesByMinute[minuteKey] ?? 0.0) + (c['value'] as num? ?? 0).toDouble();
      }
    }

    Map<String, List<double>> hrByMinute = {};
    if (recentHeartRate != null) {
      for (var hr in recentHeartRate) {
        String timeStr = hr['time'] as String? ?? "00:00:00";
        if (timeStr.compareTo(timeLimitStr) > 0) continue;
        String minuteKey = timeStr.length >= 5 ? timeStr.substring(0, 5) : "00:00";
        double val = (hr['value'] as num? ?? 0).toDouble();
        if (val > 0) hrByMinute.putIfAbsent(minuteKey, () => []).add(val);
      }
    }

    // ── 5. ANALISI COERENTE MINUTO PER MINUTO ──
    double cumulativeStressPoints = 0.0;
    double mentalStressDrain = 0.0;

    // Calcolo fisso del drenaggio mentale passivo legato alle ore di veglia
    double basalCognitiveDrain = minutesPassedToday * 0.015;

    for (String minuteKey in hrByMinute.keys) {
      List<double> hrSamples = hrByMinute[minuteKey]!;
      double avgHr = hrSamples.reduce((a, b) => a + b) / hrSamples.length;

      // Filtro 1: Esercizio Fisico Programmato (Non drena la mente, non crea stress ansioso)
      bool isExercising = false;
      if (activeExercises != null) {
        for (var exe in activeExercises) {
          String start = exe['time_start'] as String? ?? "00:00:00";
          String end = exe['time_end'] as String? ?? "00:00:00";
          String currentFullTime = "$minuteKey:00"; 
          if (currentFullTime.compareTo(start) >= 0 && currentFullTime.compareTo(end) <= 0) {
            isExercising = true;
            break;
          }
        }
      }
      if (isExercising) continue; 

      // Filtro 2: Movimento Istantaneo Spontaneo (Passi o picco calorico)
      double stepsInMin = stepsByMinute[minuteKey] ?? 0.0;
      double calsInMin = caloriesByMinute[minuteKey] ?? basalCaloriesPerMinute;
      if (stepsInMin > 15 || calsInMin > (basalCaloriesPerMinute * 3.0)) {
        continue; 
      }

      // ACCUMULO BIOMETRICO: Il soggetto è fermo ma ha il battito accelerato (> baseline + 3)
      if (avgHr > _baselineRHR + 3.0) {
        double hrElevation = avgHr - _baselineRHR;
        double intensity = (hrElevation / maxMentalElevation).clamp(0.0, 1.0); 
        
        // Riempimento Secchio Stress
        cumulativeStressPoints += intensity * maxPointsPerMinute; 
        // Svuotamento Batteria Recovery
        mentalStressDrain += intensity * maxDrainPerMinute;
      }
    }

    // ── 6. NORMALIZZAZIONE DEL CARICO GIORNALIERO GENERATO ──
    double maxPossiblePointsSoFar = minutesPassedToday * maxPointsPerMinute;
    double rawStressLevel = (cumulativeStressPoints / maxPossiblePointsSoFar) * 100.0;

    // Integrazione dell'amplificatore del sonno
    double sleepMultiplier = 1.0;
    double sleepDeficit = targetSleepDuration - actualSleepDuration; 
    if (sleepDeficit > 0) {
      sleepMultiplier += (sleepDeficit / targetSleepDuration) * 0.35; 
    }

    double inheritedStress = (rawStressLevel * sleepMultiplier) + weeklyStressPenalty;

    // ── 7. INTEGRAZIONE ATTIVA DELLA RESPIRAZIONE DI OGGI (L'ANTIDOTO) ──
    final int breathingMinutesToday = await getTodayBreathingMinutes();
    
    // Effetto del respiro sullo Stress (Sconto percentuale diretto)
    double stressReduction = breathingMinutesToday * 4.0; 
    double finalStress = inheritedStress - stressReduction;

    // Effetto del respiro sulla Recovery (Ricarica Fast-Charge)
    double rechargeFromBreathing = breathingMinutesToday * 2.5;
    double finalBattery = initialMentalBattery - basalCognitiveDrain - mentalStressDrain + rechargeFromBreathing;

    // ── 8. SALVATAGGIO DEI COMPONENTI E NOTIFICA UI ──
    _stressLevel = double.parse(finalStress.clamp(0.0, 100.0).toStringAsFixed(1));
    _recoveryLevel = double.parse(finalBattery.clamp(0.0, 100.0).toStringAsFixed(1));
    
    print("=================================================");
    print("MOTORE DI CALCOLO UNIFICATO MENTALE FINO ALLE $timeLimitStr");
    print("Minuti di elaborazione giornaliera: $minutesPassedToday min");
    print("STRESS FINALE REGISTRATO: $_stressLevel%");
    print("RECOVERY FINALE REGISTRATA: $_recoveryLevel%");
    print("=================================================");
    print("-------------------------------------------------");
    print("RECOVERY MENTALE: FINO ALLE $timeLimitStr");
    print("Batteria Iniziale (da Sonno): ${initialMentalBattery.toStringAsFixed(1)}%");
    print("Drenaggio Cognitivo Base: -${basalCognitiveDrain.toStringAsFixed(1)}%");
    print("Drenaggio da Ansia/Stress: -${mentalStressDrain.toStringAsFixed(1)}%");
    print("Ricarica da Respirazione: +${rechargeFromBreathing.toStringAsFixed(1)}%");
    print("RECOVERY ATTUALE: $_recoveryLevel%");
    print("-------------------------------------------------");
    print("-------------------------------------------------");
    print("STRESS: CALCOLO SPECCHIATO 'IERI-OGGI' FINO ALLE $timeLimitStr:");
    print("Minuti considerati sul nastro: $minutesPassedToday min");
    print("Stress Odierno Parziale: ${inheritedStress.toStringAsFixed(1)}%");
    print("Sconto Respiro di Oggi ($breathingMinutesToday min): -$stressReduction%");
    print("Moltiplicatore per sonno: $sleepMultiplier");
    print("Baseline RHR: $_baselineRHR");
    print("STRESS ATTUALE: $_stressLevel%");
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
