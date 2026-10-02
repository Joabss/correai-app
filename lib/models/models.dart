enum ActivityType { run, walk }

extension ActivityTypeX on ActivityType {
  String get api => name.toUpperCase();
  String get label => this == ActivityType.run ? 'Corrida' : 'Caminhada';

  static ActivityType parse(String v) =>
      v == 'WALK' ? ActivityType.walk : ActivityType.run;
}

const trainingTypes = {
  'EASY': 'Leve',
  'TEMPO': 'Ritmo',
  'INTERVAL': 'Intervalado',
  'LONG': 'Longo',
};

const efforts = {'EASY': 'Fácil', 'OK': 'Ok', 'HARD': 'Difícil'};

class Activity {
  Activity({
    required this.id,
    required this.type,
    required this.date,
    required this.distanceKm,
    required this.durationSeconds,
    required this.avgPace,
    this.trainingType,
    this.perceivedEffort,
    this.notes,
  });

  final String id;
  final ActivityType type;
  final DateTime date;
  final double distanceKm;
  final int durationSeconds;
  final String avgPace;
  final String? trainingType;
  final String? perceivedEffort;
  final String? notes;

  factory Activity.fromJson(Map<String, dynamic> j) => Activity(
    id: j['id'] as String,
    type: ActivityTypeX.parse(j['type'] as String),
    date: DateTime.parse(j['date'] as String),
    distanceKm: (j['distanceKm'] as num).toDouble(),
    durationSeconds: j['durationSeconds'] as int,
    avgPace: j['avgPace'] as String? ?? '--:--',
    trainingType: j['trainingType'] as String?,
    perceivedEffort: j['perceivedEffort'] as String?,
    notes: j['notes'] as String?,
  );
}

class ActivityPage {
  ActivityPage(this.content, this.page, this.totalPages);

  final List<Activity> content;
  final int page;
  final int totalPages;

  bool get hasMore => page + 1 < totalPages;

  factory ActivityPage.fromJson(Map<String, dynamic> j) => ActivityPage(
    (j['content'] as List)
        .map((e) => Activity.fromJson(e as Map<String, dynamic>))
        .toList(),
    j['page'] as int,
    j['totalPages'] as int,
  );
}

class StatsSummary {
  StatsSummary({
    required this.kmWeek,
    required this.kmMonth,
    required this.activitiesWeek,
    required this.streak,
    required this.longestDistance,
  });

  final double kmWeek;
  final double kmMonth;
  final int activitiesWeek;
  final int streak;
  final double longestDistance;

  factory StatsSummary.fromJson(Map<String, dynamic> j) => StatsSummary(
    kmWeek: (j['kmWeek'] as num).toDouble(),
    kmMonth: (j['kmMonth'] as num).toDouble(),
    activitiesWeek: j['activitiesWeek'] as int,
    streak: j['streak'] as int,
    longestDistance: (j['longestDistance'] as num).toDouble(),
  );
}

class WeekEvolution {
  WeekEvolution(this.weekStart, this.km, this.activities, this.avgPace);

  final DateTime weekStart;
  final double km;
  final int activities;
  final String? avgPace;

  factory WeekEvolution.fromJson(Map<String, dynamic> j) => WeekEvolution(
    DateTime.parse(j['weekStart'] as String),
    (j['km'] as num).toDouble(),
    j['activities'] as int,
    j['avgPace'] as String?,
  );
}

enum GoalType { distanceKm, activities, avgPace }

extension GoalTypeX on GoalType {
  String get api => switch (this) {
    GoalType.distanceKm => 'DISTANCE_KM',
    GoalType.activities => 'ACTIVITIES',
    GoalType.avgPace => 'AVG_PACE',
  };
  String get label => switch (this) {
    GoalType.distanceKm => 'Distância (km)',
    GoalType.activities => 'Atividades',
    GoalType.avgPace => 'Pace médio',
  };

  static GoalType parse(String v) => switch (v) {
    'ACTIVITIES' => GoalType.activities,
    'AVG_PACE' => GoalType.avgPace,
    _ => GoalType.distanceKm,
  };
}

enum GoalPeriod { weekly, monthly }

extension GoalPeriodX on GoalPeriod {
  String get api => name.toUpperCase();
  String get label => this == GoalPeriod.weekly ? 'Semanal' : 'Mensal';

  static GoalPeriod parse(String v) =>
      v == 'MONTHLY' ? GoalPeriod.monthly : GoalPeriod.weekly;
}

class Goal {
  Goal({
    required this.id,
    required this.type,
    required this.period,
    required this.target,
    this.targetPace,
    this.current,
    this.currentPace,
    this.percentage,
    required this.achieved,
  });

  final String id;
  final GoalType type;
  final GoalPeriod period;
  final double target;
  final String? targetPace;
  final double? current;
  final String? currentPace;
  final double? percentage;
  final bool achieved;

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
    id: j['id'] as String,
    type: GoalTypeX.parse(j['type'] as String),
    period: GoalPeriodX.parse(j['period'] as String),
    target: (j['target'] as num).toDouble(),
    targetPace: j['targetPace'] as String?,
    current: (j['current'] as num?)?.toDouble(),
    currentPace: j['currentPace'] as String?,
    percentage: (j['percentage'] as num?)?.toDouble(),
    achieved: j['achieved'] as bool,
  );
}
