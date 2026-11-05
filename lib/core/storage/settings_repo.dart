import 'package:hive_ce/hive.dart';

import '../models.dart';

class SettingsRepo {
  SettingsRepo(this._box);
  final Box<dynamic> _box;
  static const _field = 'settings';

  AppSettings load() {
    final raw = _box.get(_field);
    return raw is Map ? AppSettings.fromJson(raw) : const AppSettings();
  }

  Future<void> save(AppSettings s) => _box.put(_field, s.toJson());
}
