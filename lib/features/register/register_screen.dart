import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../models/models.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.state, required this.onSaved});

  final AppState state;
  final VoidCallback onSaved;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _distance = TextEditingController();
  final _duration = TextEditingController();
  final _notes = TextEditingController();
  ActivityType _type = ActivityType.run;
  String? _training;
  String? _effort;
  bool _saving = false;

  @override
  void dispose() {
    _distance.dispose();
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.state.repository.createActivity(
        type: _type,
        distanceKm: double.parse(_distance.text.replaceAll(',', '.')),
        durationSeconds: parseDuration(_duration.text)!,
        trainingType: _training,
        perceivedEffort: _effort,
        notes: _notes.text.trim(),
      );
      widget.state.dataChanged();
      _distance.clear();
      _duration.clear();
      _notes.clear();
      setState(() {
        _training = null;
        _effort = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Atividade registrada!')));
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<ActivityType>(
            segments: [
              for (final t in ActivityType.values)
                ButtonSegment(value: t, label: Text(t.label)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _distance,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Distância (km)',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final n = double.tryParse((v ?? '').replaceAll(',', '.'));
              return n == null || n <= 0
                  ? 'Informe uma distância válida'
                  : null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _duration,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              labelText: 'Duração (mm:ss ou h:mm:ss)',
              border: OutlineInputBorder(),
            ),
            validator: (v) => parseDuration(v ?? '') == null
                ? 'Use o formato 45:30 ou 1:05:30'
                : null,
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notas',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Salvar atividade'),
          ),
        ],
      ),
    );
  }
}
