import 'dart:math' as math;

class TrackPoint {
  const TrackPoint(this.latitude, this.longitude, this.accuracy);

  final double latitude;
  final double longitude;
  final double accuracy;
}

/// Haversine distance in meters.
double distanceMeters(TrackPoint a, TrackPoint b) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.latitude - a.latitude);
  final dLon = rad(b.longitude - a.longitude);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitude)) *
          math.cos(rad(b.latitude)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}

/// Accumulates distance from GPS points, ignoring inaccurate fixes and jitter.
class TrackCalculator {
  TrackCalculator({this.maxAccuracy = 30, this.minStep = 3});

  final double maxAccuracy;
  final double minStep;

  TrackPoint? _last;
  double _meters = 0;

  double get meters => _meters;
  double get km => _meters / 1000;

  /// Returns true when the point increased the distance.
  bool add(TrackPoint p) {
    if (p.accuracy > maxAccuracy) return false;
    final last = _last;
    if (last == null) {
      _last = p;
      return false;
    }
    final step = distanceMeters(last, p);
    if (step < math.max(minStep, p.accuracy / 4)) return false;
    _meters += step;
    _last = p;
    return true;
  }

  /// Drops the reference point so the gap while paused is not counted.
  void breakSegment() => _last = null;

  void reset() {
    _last = null;
    _meters = 0;
  }
}
