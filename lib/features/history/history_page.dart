import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/history_repo.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../ui/dialogs.dart';
import '../collage/collage_spec.dart';
import '../../state/collage_providers.dart';
import '../result/result_page.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final all = ref.watch(historyProvider);
    final filter = ref.watch(historyFilterProvider);
    final items = all.where(filter.matches).toList();
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l.tabHistory),
            automaticallyImplyLeading: false,
          ),
          if (all.isNotEmpty) const SliverToBoxAdapter(child: _FilterBar()),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: all.isEmpty
                    ? Text(l.historyEmpty, style: TextStyle(color: secondary))
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l.historyNoMatch,
                            style: TextStyle(color: secondary),
                          ),
                          CupertinoButton(
                            onPressed: () =>
                                ref.read(historyFilterProvider.notifier).state =
                                    const HistoryFilter(),
                            child: Text(l.resetFilters),
                          ),
                        ],
                      ),
              ),
            )
          else
            SliverSafeArea(
              top: false,
              sliver: SliverList.builder(
                itemCount: items.length,
                itemBuilder: (_, i) => _Row(entry: items[i]),
              ),
            ),
        ],
      ),
    );
  }
}

String _day(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> _pickRange(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final set = ref.read(historyFilterProvider.notifier);
    final cur = ref.read(historyFilterProvider);
    final choice = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          for (final (id, label) in [
            ('all', l.rangeAll),
            ('today', l.rangeToday),
            ('7', l.range7),
            ('30', l.range30),
            ('custom', l.rangeCustom),
          ])
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, id),
              child: Text(label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    final today = _today();
    HistoryFilter next(DateTime? from, DateTime? to) =>
        HistoryFilter(kind: cur.kind, from: from, to: to);
    switch (choice) {
      case 'all':
        set.state = next(null, null);
      case 'today':
        set.state = next(today, today);
      case '7':
        set.state = next(today.subtract(const Duration(days: 6)), today);
      case '30':
        set.state = next(today.subtract(const Duration(days: 29)), today);
      case 'custom':
        final r = await showCupertinoModalPopup<(DateTime, DateTime)>(
          context: context,
          builder: (_) => _RangeSheet(
            start: cur.from ?? today.subtract(const Duration(days: 6)),
            end: cur.to ?? today,
          ),
        );
        if (r != null) set.state = next(r.$1, r.$2);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final f = ref.watch(historyFilterProvider);
    final set = ref.read(historyFilterProvider.notifier);
    final ranged = f.from != null || f.to != null;
    final blue = CupertinoTheme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: f.kind == null ? 0 : (f.kind! ? 2 : 1),
              children: {
                0: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(l.historyAll),
                ),
                1: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(l.modeRecolor),
                ),
                2: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(l.modeCollage),
                ),
              },
              onValueChanged: (v) {
                if (v == null) return;
                set.state = HistoryFilter(
                  kind: v == 0 ? null : v == 2,
                  from: f.from,
                  to: f.to,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(44, 44),
            onPressed: () => _pickRange(context, ref),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 20,
                  color: ranged ? blue : null,
                ),
                if (ranged) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${_day(f.from ?? f.to!)} – ${_day(f.to ?? f.from!)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeSheet extends StatefulWidget {
  const _RangeSheet({required this.start, required this.end});
  final DateTime start, end;

  @override
  State<_RangeSheet> createState() => _RangeSheetState();
}

class _RangeSheetState extends State<_RangeSheet> {
  late DateTime _start = widget.start, _end = widget.end;
  bool _editStart = true;

  String _full(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final blue = CupertinoTheme.of(context).primaryColor;
    Widget chip(String label, DateTime d, bool start) => Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _editStart = start),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _editStart == start
                  ? blue
                  : CupertinoColors.separator.resolveFrom(context),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(_full(d), style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
    return Container(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  chip(l.rangeStart, _start, true),
                  const SizedBox(width: 12),
                  chip(l.rangeEnd, _end, false),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                key: ValueKey(_editStart),
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _editStart ? _start : _end,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (d) => setState(() {
                  final day = DateTime(d.year, d.month, d.day);
                  if (_editStart) {
                    _start = day;
                    if (_end.isBefore(_start)) _end = _start;
                  } else {
                    _end = day;
                    if (_start.isAfter(_end)) _start = _end;
                  }
                }),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.cancel),
                  ),
                ),
                Expanded(
                  child: CupertinoButton(
                    onPressed: () => Navigator.pop(context, (_start, _end)),
                    child: Text(l.done),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.entry});
  final HistoryEntry entry;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final nav = Navigator.of(context, rootNavigator: true);
    final r = await File(entry.resultPath).readAsBytes();
    final o = entry.isCollage
        ? null
        : await File(entry.originalPath).readAsBytes();
    if (!context.mounted) return;
    nav.push(
      CupertinoPageRoute<void>(
        builder: (ctx) => ResultPage(
          entryId: entry.id,
          original: o,
          result: r,
          onTweak: () => entry.isCollage
              ? _adjustCollage(ctx, ref)
              : _adjustRecolor(ctx, ref, r, o!),
        ),
      ),
    );
  }

  Future<void> _adjustCollage(BuildContext ctx, WidgetRef ref) async {
    final sources = [
      for (final p in entry.sourcePaths) await File(p).readAsBytes(),
    ];
    await ref
        .read(collageProvider.notifier)
        .load(sources, CollageSpec.fromJson(entry.spec!));
    ref.read(createModeProvider.notifier).state = CreateMode.collage;
    if (ctx.mounted) _toCreate(ctx, ref);
  }

  Future<void> _adjustRecolor(
    BuildContext ctx,
    WidgetRef ref,
    Uint8List result,
    Uint8List original,
  ) async {
    final l = AppLocalizations.of(ctx);
    final fromResult = await showCupertinoModalPopup<bool>(
      context: ctx,
      builder: (c) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.adjustFromResult),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.adjustFromOriginal),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(c),
          child: Text(l.cancel),
        ),
      ),
    );
    if (fromResult == null || !ctx.mounted) return;
    await ref
        .read(editProvider.notifier)
        .continueFrom(
          fromResult ? result : original,
          prompt: fromResult ? '' : entry.prompt,
        );
    ref.read(createModeProvider.notifier).state = CreateMode.recolor;
    if (ctx.mounted) _toCreate(ctx, ref);
  }

  void _toCreate(BuildContext ctx, WidgetRef ref) {
    Navigator.of(ctx).pop();
    ref.read(tabControllerProvider).index = 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final date = entry.createdAt;
    final when =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final label = entry.name.isNotEmpty
        ? entry.name
        : entry.isCollage
        ? (entry.prompt.isEmpty
              ? l.historyCollage
              : '${l.historyCollage} · ${entry.prompt}')
        : (entry.auto || entry.prompt.isEmpty ? l.modeAuto : entry.prompt);
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDeleteConfirm(context),
      onDismissed: (_) => ref.read(historyProvider.notifier).delete(entry),
      background: Container(
        color: CupertinoColors.destructiveRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white),
      ),
      child: CupertinoListTile.notched(
        leadingSize: 56,
        leading: ClipRSuperellipse(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(entry.resultPath),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            cacheWidth: 168,
          ),
        ),
        title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(when),
        trailing: const CupertinoListTileChevron(),
        onTap: () => _open(context, ref),
      ),
    );
  }
}
