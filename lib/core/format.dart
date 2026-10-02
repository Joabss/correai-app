String formatPace(int? secondsPerKm) {
  if (secondsPerKm == null || secondsPerKm <= 0) return '--:--';
  final m = secondsPerKm ~/ 60;
  final s = secondsPerKm % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

String formatKm(num km) => '${km.toStringAsFixed(km % 1 == 0 ? 0 : 2)} km';

/// Parses "mm:ss" into seconds, or null when invalid.
int? parsePace(String text) {
  final parts = text.trim().split(':');
  if (parts.length != 2) return null;
  final m = int.tryParse(parts[0]);
  final s = int.tryParse(parts[1]);
  if (m == null || s == null || s < 0 || s > 59 || m < 0) return null;
  final total = m * 60 + s;
  return total > 0 ? total : null;
}

/// Parses "h:mm:ss" or "mm:ss" into seconds, or null when invalid.
int? parseDuration(String text) {
  final parts = text.trim().split(':').map(int.tryParse).toList();
  if (parts.any((p) => p == null || p < 0) ||
      parts.length < 2 ||
      parts.length > 3) {
    return null;
  }
  final values = parts.cast<int>();
  final total = values.length == 3
      ? values[0] * 3600 + values[1] * 60 + values[2]
      : values[0] * 60 + values[1];
  return total > 0 ? total : null;
}
