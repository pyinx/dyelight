import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;

import '../../core/image/image_saver.dart';
import '../../core/storage/history_repo.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../ui/dialogs.dart';
import 'compare_viewer.dart';

class ResultPage extends ConsumerStatefulWidget {
  const ResultPage({
    super.key,
    this.original,
    required this.result,
    this.onTweak,
    this.entryId,
  });

  /// null for collages: there is nothing to compare against.
  final Uint8List? original;
  final Uint8List result;

  /// Set when opened from History: enables rename and delete.
  final String? entryId;

  /// null hides the Tweak action (e.g. when opened from history).
  final VoidCallback? onTweak;

  @override
  ConsumerState<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends ConsumerState<ResultPage> {
  bool _chrome = true;
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l = AppLocalizations.of(context);
    final outcome = await ref
        .read(imageSaverProvider)
        .saveToGallery(widget.result);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (outcome) {
      case SaveOutcome.saved:
        HapticFeedback.mediumImpact();
        showToast(context, l.saved);
      case SaveOutcome.noAccess:
        showPermissionDialog(context, l.permPhotosBody, openAppSettings);
      case SaveOutcome.failed:
        showInfoDialog(context, l.saveFailed);
    }
  }

  HistoryEntry? get _entry {
    final id = widget.entryId;
    if (id == null) return null;
    return ref.watch(historyProvider).where((e) => e.id == id).firstOrNull;
  }

  Future<void> _rename(HistoryEntry e) async {
    final name = await showRenameDialog(context, e.name);
    if (name == null || !mounted) return;
    await ref.read(historyProvider.notifier).rename(e, name);
  }

  Future<void> _delete(HistoryEntry e) async {
    if (!await showDeleteConfirm(context) || !mounted) return;
    await ref.read(historyProvider.notifier).delete(e);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pad = MediaQuery.paddingOf(context);
    final entry = _entry;
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.original == null)
            GestureDetector(
              onTap: () => setState(() => _chrome = !_chrome),
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(child: Image.memory(widget.result)),
              ),
            )
          else
            CompareViewer(
              original: widget.original!,
              result: widget.result,
              originalLabel: l.original,
              resultLabel: 'AI',
              onTap: () => setState(() => _chrome = !_chrome),
            ),
          AnimatedOpacity(
            opacity: _chrome ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            child: IgnorePointer(
              ignoring: !_chrome,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _Blur(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: pad.top,
                          left: 4,
                          right: 16,
                        ),
                        child: SizedBox(
                          height: 44,
                          child: Row(
                            children: [
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                child: const Icon(
                                  CupertinoIcons.chevron_back,
                                  color: CupertinoColors.white,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry != null && entry.name.isNotEmpty
                                      ? entry.name
                                      : l.resultTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                              if (entry == null)
                                const SizedBox(width: 48)
                              else ...[
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  minimumSize: const Size(44, 44),
                                  onPressed: () => _rename(entry),
                                  child: Icon(
                                    CupertinoIcons.pencil,
                                    color: CupertinoColors.white,
                                    semanticLabel: l.rename,
                                  ),
                                ),
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  minimumSize: const Size(44, 44),
                                  onPressed: () => _delete(entry),
                                  child: Icon(
                                    CupertinoIcons.delete,
                                    color: CupertinoColors.systemRed,
                                    semanticLabel: l.delete,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _Blur(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          10,
                          16,
                          pad.bottom + 10,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.original != null) ...[
                              Text(
                                l.holdForOriginal,
                                style: const TextStyle(
                                  color: Color(0xB3FFFFFF),
                                  fontSize: 12,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              children: [
                                if (widget.onTweak != null) ...[
                                  Expanded(
                                    child: CupertinoButton(
                                      color: const Color(0x33FFFFFF),
                                      borderRadius: BorderRadius.circular(14),
                                      onPressed: widget.onTweak,
                                      child: Text(
                                        l.tweak,
                                        style: const TextStyle(
                                          color: CupertinoColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: CupertinoButton.filled(
                                    borderRadius: BorderRadius.circular(14),
                                    onPressed: _saving ? null : _save,
                                    child: _saving
                                        ? const CupertinoActivityIndicator()
                                        : Text(l.save),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blur extends StatelessWidget {
  const _Blur({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: ColoredBox(color: const Color(0x55000000), child: child),
    ),
  );
}
