import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ZeroStress/services/impact.dart';

class HealthDataProvider extends ChangeNotifier {

  bool _hasHealthData = false;

  // ── RHR Settimanale ────────────────────────────────────────────────────────
  List<double?> _weeklyRHR = List.filled(7, null);
  double _baselineRHR = 0.0;

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

  // ─────────────────────────────────────────────────────────────────────────
  // FETCH PRINCIPALE
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {

      final weeklyRHR = await Impact.fetchWeeklyRestingHeartRate();
      
      _computeWeeklyRHR(weeklyRHR);
      await _loadStreak();

      _hasHealthData = true;
      print('prova');
    } catch (e) {
      print('ciao');
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

  // IMPLEMENTARE _computeStress(


  // ─────────────────────────────────────────────────────────────────────────
  // STREAK
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadStreak() async {
    final sp = await SharedPreferences.getInstance();
    _currentStreak = sp.getInt('streak_count') ?? 0;

    final today = DateTime.now();
    final List<bool> completed = List.filled(7, false);
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final idx = day.weekday - 1; // Mon=0 … Sun=6
      completed[idx] = sp.getBool('streak_day_${_dateKey(day)}') ?? false;
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
    final yesterdayDone =
        sp.getBool('streak_day_${_dateKey(yesterday)}') ?? false;

    if (yesterdayDone || _currentStreak == 0) {
      _currentStreak++;
    } else {
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
