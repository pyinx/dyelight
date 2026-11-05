import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/storage/history_repo.dart';
import 'core/storage/settings_repo.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final docs = await getApplicationDocumentsDirectory();
  Hive.init(p.join(docs.path, 'hive'));
  final settingsBox = await Hive.openBox<dynamic>('settings');
  final historyBox = await Hive.openBox<dynamic>('history');
  runApp(
    ProviderScope(
      overrides: [
        settingsRepoProvider.overrideWithValue(SettingsRepo(settingsBox)),
        historyRepoProvider.overrideWithValue(
          HistoryRepo(historyBox, Directory(p.join(docs.path, 'history'))),
        ),
      ],
      child: const App(),
    ),
  );
}
