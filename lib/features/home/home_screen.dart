import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/async_view.dart';
import '../../core/format.dart';
import '../../models/models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AsyncView<(StatsSummary, List<WeekEvolution>)>(
      reloadOn: state,
      load: () async {
        final summary = await state.repository.summary();
        final evolution = await state.repository.evolution(weeks: 8);
        return (summary, evolution);
      },
      builder: (context, data, refresh) {
        final (summary, evolution) = data;
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Seu resumo', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  _StatCard('Semana', formatKm(summary.kmWeek), Icons.calendar_view_week),
                  _StatCard('Mês', formatKm(summary.kmMonth), Icons.calendar_month),
                  _StatCard('Sequência', '${summary.streak} dias', Icons.local_fire_department),
                  _StatCard('Maior distância', formatKm(summary.longestDistance), Icons.emoji_events),
                ],
              ),
              const SizedBox(height: 24),
              Text('Evolução semanal (km)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(height: 180, child: EvolutionChart(weeks: evolution)),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(label)]),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class EvolutionChart extends StatelessWidget {
  const EvolutionChart({super.key, required this.weeks});

  final List<WeekEvolution> weeks;

  @override
  Widget build(BuildContext context) {
    final maxKm = weeks.fold<double>(0, (m, w) => w.km > m ? w.km : m);
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final w in weeks)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(w.km == 0 ? '' : w.km.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Container(
                    height: maxKm == 0 ? 2 : 2 + (w.km / maxKm) * 120,
                    decoration: BoxDecoration(
                      color: w.km == 0 ? color.withValues(alpha: 0.25) : color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${w.weekStart.day.toString().padLeft(2, '0')}/${w.weekStart.month.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
