import 'package:correai_app/features/track/track_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ~111 m per 0.001 degree of latitude.
  TrackPoint at(double lat, {double acc = 5}) => TrackPoint(lat, -46.0, acc);

  test('accumulates distance between accurate points', () {
    final c = TrackCalculator();
    expect(c.add(at(-23.000)), isFalse);
    expect(c.add(at(-23.001)), isTrue);
    expect(c.add(at(-23.002)), isTrue);
    expect(c.meters, closeTo(222, 3));
  });

  test('ignores inaccurate points and jitter', () {
    final c = TrackCalculator();
    c.add(at(-23.000));
    expect(c.add(at(-23.010, acc: 80)), isFalse);
    expect(c.add(at(-23.00001)), isFalse);
    expect(c.meters, 0);
  });

  test('breakSegment does not count the gap', () {
    final c = TrackCalculator();
    c.add(at(-23.000));
    c.add(at(-23.001));
    c.breakSegment();
    expect(c.add(at(-23.100)), isFalse);
    expect(c.meters, closeTo(111, 2));
  });

  test('distance of one degree of latitude', () {
    expect(distanceMeters(at(0), at(1)), closeTo(111195, 100));
  });
}
