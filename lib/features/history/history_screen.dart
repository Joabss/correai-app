import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../models/models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.state});

  final AppState state;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _items = <Activity>[];
  final _scroll = ScrollController();
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_reset);
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) _loadMore();
    });
    _loadMore();
  }

  @override
  void dispose() {
    widget.state.removeListener(_reset);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    _items.clear();
    _page = 0;
    _hasMore = true;
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.state.repository.activities(page: _page);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.content);
        _hasMore = page.hasMore;
        _page++;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(Activity a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remover atividade?'),
        content: Text(
          '${a.type.label} de ${formatKm(a.distanceKm)} será removida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.state.repository.deleteActivity(a.id);
      widget.state.dataChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadMore,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('Nenhuma atividade ainda. Registre a primeira!'),
      );
    }
    return RefreshIndicator(
      onRefresh: _reset,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final a = _items[i];
          final d = a.date;
          return ListTile(
            leading: Icon(
              a.type == ActivityType.run
                  ? Icons.directions_run
                  : Icons.directions_walk,
            ),
            title: Text(
              '${formatKm(a.distanceKm)} • ${formatDuration(a.durationSeconds)}',
            ),
            subtitle: Text(
              '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}'
              ' • pace ${a.avgPace}'
              '${a.trainingType != null ? ' • ${trainingTypes[a.trainingType] ?? a.trainingType}' : ''}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(a),
            ),
          );
        },
      ),
    );
  }
}
