import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/async_view.dart';
import '../../core/format.dart';
import '../../models/models.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key, required this.state});

  final AppState state;

  Future<void> _create(BuildContext context) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _NewGoalDialog(state: state),
    );
    if (created == true) state.dataChanged();
  }

  Future<void> _delete(BuildContext context, Goal goal) async {
    try {
      await state.repository.deleteGoal(goal.id);
      state.dataChanged();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  String _targetText(Goal g) => g.type == GoalType.avgPace
      ? 'até ${g.targetPace ?? formatPace(g.target.toInt())} /km'
      : g.type == GoalType.distanceKm
          ? formatKm(g.target)
          : '${g.target.toInt()} atividades';

  String _currentText(Goal g) {
    if (g.current == null) return '';
    return switch (g.type) {
      GoalType.avgPace => 'Atual: ${g.currentPace ?? '--:--'} /km',
      GoalType.distanceKm => 'Atual: ${formatKm(g.current!)}',
      GoalType.activities => 'Atual: ${g.current!.toInt()}',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova meta'),
      ),
      body: AsyncView<List<Goal>>(
        reloadOn: state,
        load: state.repository.goals,
        builder: (context, goals, refresh) {
          if (goals.isEmpty) {
            return const Center(child: Text('Nenhuma meta ativa. Crie a primeira!'));
          }
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                for (final g in goals)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('${g.type.label} • ${g.period.label}',
                                    style: Theme.of(context).textTheme.titleMedium),
                              ),
                              if (g.achieved)
                                const Icon(Icons.check_circle, color: Colors.green),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(context, g),
                              ),
                            ],
                          ),
                          Text('Meta: ${_targetText(g)}'),
                          Text(_currentText(g)),
                          if (g.percentage != null) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: (g.percentage! / 100).clamp(0.0, 1.0),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NewGoalDialog extends StatefulWidget {
  const _NewGoalDialog({required this.state});

  final AppState state;

  @override
  State<_NewGoalDialog> createState() => _NewGoalDialogState();
}

class _NewGoalDialogState extends State<_NewGoalDialog> {
  final _target = TextEditingController();
  GoalType _type = GoalType.distanceKm;
  GoalPeriod _period = GoalPeriod.weekly;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final double? target = _type == GoalType.avgPace
        ? parsePace(_target.text)?.toDouble()
        : double.tryParse(_target.text.replaceAll(',', '.'));
    if (target == null || target <= 0) {
      setState(() => _error = _type == GoalType.avgPace ? 'Use o formato 05:30' : 'Valor inválido');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.state.repository.createGoal(_type, _period, target);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova meta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<GoalType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: [for (final t in GoalType.values) DropdownMenuItem(value: t, child: Text(t.label))],
              onChanged: (v) => setState(() {
                _type = v!;
                _error = null;
              }),
            ),
            DropdownButtonFormField<GoalPeriod>(
              initialValue: _period,
              decoration: const InputDecoration(labelText: 'Período'),
              items: [for (final p in GoalPeriod.values) DropdownMenuItem(value: p, child: Text(p.label))],
              onChanged: (v) => setState(() => _period = v!),
            ),
            TextField(
              controller: _target,
              keyboardType: _type == GoalType.avgPace
                  ? TextInputType.datetime
                  : const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: switch (_type) {
                  GoalType.distanceKm => 'Meta (km)',
                  GoalType.activities => 'Meta (nº de atividades)',
                  GoalType.avgPace => 'Pace máximo (mm:ss por km)',
                },
                errorText: _error,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Salvar')),
      ],
    );
  }
}
