import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/debug_log.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../ui/dialogs.dart';

class DebugLogPage extends ConsumerWidget {
  const DebugLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l.debugTitle),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: debugLog.clear,
          child: Text(l.debugClear),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder<List<String>>(
                valueListenable: debugLog.entries,
                builder: (context, items, _) {
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l.debugEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => SelectableText(
                      items[i],
                      style: const TextStyle(
                        fontFamily: 'Menlo',
                        fontFamilyFallback: ['monospace'],
                        fontSize: 11.5,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(14),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: debugLog.report(
                          settings,
                          appVersion:
                              ref.read(appVersionProvider).valueOrNull ?? '',
                        ),
                      ),
                    );
                    HapticFeedback.mediumImpact();
                    if (context.mounted) showToast(context, l.debugCopied);
                  },
                  child: Text(l.debugCopy),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
