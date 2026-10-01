import 'package:correai_app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses goal with pace', () {
    final g = Goal.fromJson({
      'id': 'x', 'type': 'AVG_PACE', 'period': 'WEEKLY', 'target': 330.0,
      'targetPace': '05:30', 'current': 300.0, 'currentPace': '05:00',
      'percentage': null, 'achieved': true,
    });
    expect(g.type, GoalType.avgPace);
    expect(g.percentage, isNull);
    expect(g.achieved, isTrue);
  });

  test('parses activity page', () {
    final p = ActivityPage.fromJson({
      'content': [
        {'id': 'a', 'type': 'RUN', 'date': '2026-09-30', 'distanceKm': 10.0,
         'avgPace': '05:00', 'durationSeconds': 3000}
      ],
      'page': 0, 'size': 20, 'totalElements': 30, 'totalPages': 2,
    });
    expect(p.content.single.distanceKm, 10.0);
    expect(p.hasMore, isTrue);
  });
}
