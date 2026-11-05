import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/history/history_page.dart';
import 'features/home/create_page.dart';
import 'features/settings/settings_page.dart';
import 'l10n/app_localizations.dart';
import 'state/collage_providers.dart';
import 'state/providers.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(settingsProvider.select((s) => s.localeCode));
    return CupertinoApp(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      debugShowCheckedModeBanner: false,
      locale: code == null ? null : Locale(code),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
      ],
      theme: const CupertinoThemeData(primaryColor: CupertinoColors.systemBlue),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return CupertinoTabScaffold(
      controller: ref.watch(tabControllerProvider),
      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.wand_stars),
            label: l.tabCreate,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.clock),
            label: l.tabHistory,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.gear),
            label: l.tabSettings,
          ),
        ],
      ),
      tabBuilder: (context, i) => CupertinoTabView(
        builder: (_) => switch (i) {
          0 => const CreatePage(),
          1 => const HistoryPage(),
          _ => const SettingsPage(),
        },
      ),
    );
  }
}
