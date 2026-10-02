import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'track_calculator.dart';

enum TrackStatus { idle, running, paused }

class TrackController extends ChangeNotifier {
  final _calc = TrackCalculator();
  final _stopwatch = Stopwatch();
  StreamSubscription<Position>? _sub;
  Timer? _ticker;

  TrackStatus status = TrackStatus.idle;
  String? error;

  double get km => _calc.km;
  int get elapsedSeconds => _stopwatch.elapsed.inSeconds;

  /// Average pace in seconds per km, or null before 50 m are covered.
  int? get paceSeconds =>
      _calc.meters < 50 ? null : (elapsedSeconds / km).round();

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      error = 'Ative o GPS do aparelho.';
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      error =
          'Permissão de localização negada. Libere nas configurações do app.';
      return false;
    }
    return true;
  }

  Future<void> start() async {
    error = null;
    if (!await _ensurePermission()) {
      notifyListeners();
      return;
    }
    _calc.reset();
    _stopwatch
      ..reset()
      ..start();
    _listen();
    status = TrackStatus.running;
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
    notifyListeners();
  }

  void _listen() {
    _sub =
        Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 3,
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'CorreAI',
              notificationText: 'Gravando sua atividade',
              enableWakeLock: true,
            ),
          ),
        ).listen(
          (p) {
            if (status != TrackStatus.running) return;
            if (_calc.add(TrackPoint(p.latitude, p.longitude, p.accuracy))) {
              notifyListeners();
            }
          },
          onError: (_) {
            error = 'Falha ao ler o GPS.';
            notifyListeners();
          },
        );
  }

  void pause() {
    if (status != TrackStatus.running) return;
    _stopwatch.stop();
    _sub?.cancel();
    _sub = null;
    _calc.breakSegment();
    status = TrackStatus.paused;
    notifyListeners();
  }

  void resume() {
    if (status != TrackStatus.paused) return;
    _stopwatch.start();
    _listen();
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
    status = TrackStatus.running;
    notifyListeners();
  }

  /// Stops tracking and keeps the totals readable until [discard] is called.
  void finish() {
    _stopwatch.stop();
    _sub?.cancel();
    _sub = null;
    _ticker?.cancel();
    _ticker = null;
    status = TrackStatus.paused;
    notifyListeners();
  }

  void discard() {
    finish();
    _calc.reset();
    _stopwatch.reset();
    status = TrackStatus.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }
}
