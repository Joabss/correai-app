import '../models/models.dart';
import 'api_client.dart';

class CorreAiRepository {
  CorreAiRepository(this._api);

  final ApiClient _api;

  Future<StatsSummary> summary() async => StatsSummary.fromJson(
    await _api.get('/stats/summary') as Map<String, dynamic>,
  );

  Future<List<WeekEvolution>> evolution({int weeks = 8}) async {
    final json = await _api.get(
      '/stats/evolution',
      query: {'weeks': '$weeks'},
    ) as Map<String, dynamic>;
    return (json['items'] as List)
        .map((e) => WeekEvolution.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ActivityPage> activities({int page = 0, int size = 20}) async =>
      ActivityPage.fromJson(
        await _api.get('/activities', query: {'page': '$page', 'size': '$size'})
            as Map<String, dynamic>,
      );

  Future<void> createActivity({
    required ActivityType type,
    required double distanceKm,
    required int durationSeconds,
    String? trainingType,
    String? perceivedEffort,
    String? notes,
  }) => _api.post('/activities', {
    'type': type.api,
    'distanceKm': distanceKm,
    'durationSeconds': durationSeconds,
    'trainingType': ?trainingType,
    'perceivedEffort': ?perceivedEffort,
    if (notes != null && notes.isNotEmpty) 'notes': notes,
  });

  Future<void> deleteActivity(String id) => _api.delete('/activities/$id');

  Future<List<Goal>> goals() async => (await _api.get('/goals') as List)
      .map((e) => Goal.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<void> createGoal(GoalType type, GoalPeriod period, double target) =>
      _api.post('/goals', {
        'type': type.api,
        'period': period.api,
        'target': target,
      });

  Future<void> deleteGoal(String id) => _api.delete('/goals/$id');
}
