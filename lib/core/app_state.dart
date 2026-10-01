import 'package:flutter/foundation.dart';

import 'repository.dart';

/// Shared state: exposes the repository and a revision counter that screens
/// watch to reload after data changes.
class AppState extends ChangeNotifier {
  AppState(this.repository);

  final CorreAiRepository repository;
  int _revision = 0;

  int get revision => _revision;

  void dataChanged() {
    _revision++;
    notifyListeners();
  }
}
