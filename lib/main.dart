import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/app_state.dart';
import 'core/async_view.dart';
import 'core/repository.dart';
import 'features/goals/goals_screen.dart';
import 'features/history/history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/register/register_screen.dart';
import 'features/track/track_controller.dart';
import 'features/track/track_screen.dart';

void main() {
  runApp(CorreAiApp(api: ApiClient()));
}

class CorreAiApp extends StatelessWidget {
  const CorreAiApp({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CorreAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: AsyncView<void>(
        load: api.init,
        builder: (context, _, _) =>
            AppShell(state: AppState(CorreAiRepository(api))),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state});

  final AppState state;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _track = TrackController();
  int _index = 0;

  static const _titles = [
    'Início',
    'Histórico',
    'Gravar',
    'Registrar',
    'Metas',
  ];

  @override
  void dispose() {
    _track.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(state: widget.state),
      HistoryScreen(state: widget.state),
      TrackScreen(
        state: widget.state,
        controller: _track,
        onSaved: () => setState(() => _index = 1),
      ),
      RegisterScreen(
        state: widget.state,
        onSaved: () => setState(() => _index = 1),
      ),
      GoalsScreen(state: widget.state),
    ];
    return Scaffold(
      appBar: AppBar(title: Text('CorreAI • ${_titles[_index]}')),
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Histórico'),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle),
            label: 'Gravar',
          ),
          NavigationDestination(icon: Icon(Icons.edit_note), label: 'Manual'),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Metas',
          ),
        ],
      ),
    );
  }
}
