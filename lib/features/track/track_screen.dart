import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import 'track_controller.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({
    super.key,
    required this.state,
    required this.controller,
    required this.onSaved,
  });

  final AppState state;
  final TrackController controller;
  final VoidCallback onSaved;

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  TrackController get c => widget.controller;

  Future<void> _finish() async {
    c.pause();
    if (c.km < 0.01 || c.elapsedSeconds < 1) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('Atividade muito curta'),
          content: const Text('Nenhuma distância foi registrada. Descartar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Continuar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
      if (discard == true) {
        c.discard();
      } else {
        c.resume();
      }
      return;
    }
    c.finish();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SaveSheet(state: widget.state, controller: c),
    );
    if (saved == true) {
      c.discard();
      widget.onSaved();
    } else {
      c.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final big = Theme.of(context).textTheme.displayMedium;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(formatDuration(c.elapsedSeconds), style: big),
              const Text('tempo'),
              const SizedBox(height: 24),
              Text(c.km.toStringAsFixed(2), style: big),
              const Text('km'),
              const SizedBox(height: 24),
              Text(formatPace(c.paceSeconds), style: big),
              const Text('pace médio (min/km)'),
              const SizedBox(height: 32),
              if (c.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    c.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              _buttons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buttons() {
    switch (c.status) {
      case TrackStatus.idle:
        return FilledButton.icon(
          onPressed: c.start,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Iniciar'),
        );
      case TrackStatus.running:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: c.pause,
              icon: const Icon(Icons.pause),
              label: const Text('Pausar'),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: _finish,
              icon: const Icon(Icons.stop),
              label: const Text('Finalizar'),
            ),
          ],
        );
      case TrackStatus.paused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: c.resume,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Retomar'),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: _finish,
              icon: const Icon(Icons.stop),
              label: const Text('Finalizar'),
            ),
          ],
        );
    }
  }
}

class _SaveSheet extends StatefulWidget {
  const _SaveSheet({required this.state, required this.controller});

  final AppState state;
  final TrackController controller;

  @override
  State<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<_SaveSheet> {
  ActivityType _type = ActivityType.run;
  String? _training;
  String? _effort;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.state.repository.createActivity(
        type: _type,
        distanceKm: double.parse(widget.controller.km.toStringAsFixed(2)),
        durationSeconds: widget.controller.elapsedSeconds,
        trainingType: _training,
        perceivedEffort: _effort,
      );
      widget.state.dataChanged();
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
    final c = widget.controller;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${c.km.toStringAsFixed(2)} km em ${formatDuration(c.elapsedSeconds)}',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SegmentedButton<ActivityType>(
              segments: [
                for (final t in ActivityType.values)
                  ButtonSegment(value: t, label: Text(t.label)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _training,
              decoration: const InputDecoration(
                labelText: 'Tipo de treino',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final e in trainingTypes.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _training = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _effort,
              decoration: const InputDecoration(
                labelText: 'Esforço percebido',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final e in efforts.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _effort = v),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Salvar atividade'),
            ),
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context, false),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}
