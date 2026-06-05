import 'dart:async';
import 'package:flutter/material.dart';
import 'package:polar/polar.dart';

enum PolarConnectionState { disconnected, connecting, connected, error }

class PolarProvider extends ChangeNotifier {
  static const String _polarId = 'CEB0E124';
  final _polar = Polar();

  PolarConnectionState _connectionState = PolarConnectionState.disconnected;
  PolarConnectionState get connectionState => _connectionState;

  int? _latestHr;
  int? get latestHr => _latestHr;

  StreamSubscription? _hrSubscription;

  // initialization of providers
  PolarProvider() {
    _polar.deviceConnected.listen((_) {
      _connectionState = PolarConnectionState.connected;
      notifyListeners();
    });

    _polar.deviceDisconnected.listen((_) {
      _connectionState = PolarConnectionState.disconnected;
      _latestHr = null;
      _hrSubscription?.cancel();
      notifyListeners();
    });

    _polar.sdkFeatureReady.listen((event) {
      if (event.feature == PolarSdkFeature.hr) {
        _startHrStreaming();
      }
    });
  }

  Future<void> connect() async {
    _connectionState = PolarConnectionState.connecting;
    notifyListeners();
    
    try {
      await _polar.connectToDevice(_polarId);
    } catch (_) {
      _connectionState = PolarConnectionState.error;
      notifyListeners();
    }
  }

  void _startHrStreaming() {
    _hrSubscription?.cancel();
    _hrSubscription = _polar.startHrStreaming(_polarId).listen(
      (data) {
        if (data.samples.isNotEmpty) {
          _latestHr = data.samples.last.hr;
          notifyListeners(); 
        }
      },
    );
  }

  void disconnect() {
    _hrSubscription?.cancel();
    _connectionState = PolarConnectionState.disconnected;
    _latestHr = null;
    
    // Ritardiamo la notifica di un istante impercettibile per farle saltare il blocco del "dispose"
    Future.microtask(() {
      notifyListeners();
    });
    
    try {
      _polar.disconnectFromDevice(_polarId);
    } catch (_) {}
  }

  @override
  void dispose() {
    _hrSubscription?.cancel();
    super.dispose();
  }
}