import 'package:correai_app/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats pace and duration', () {
    expect(formatPace(330), '05:30');
    expect(formatPace(null), '--:--');
    expect(formatDuration(3930), '1:05:30');
    expect(formatDuration(1800), '30:00');
  });

  test('parses pace and duration', () {
    expect(parsePace('05:30'), 330);
    expect(parsePace('5:75'), isNull);
    expect(parseDuration('45:30'), 2730);
    expect(parseDuration('1:05:30'), 3930);
    expect(parseDuration('abc'), isNull);
  });
}
