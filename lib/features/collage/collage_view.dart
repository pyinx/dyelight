import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../state/collage_providers.dart';
import '../../ui/dialogs.dart';
import '../home/workspace_back.dart';
import '../result/result_page.dart';
import 'collage_renderer.dart';
import 'collage_spec.dart';

class CollageView extends ConsumerStatefulWidget {
  const CollageView({super.key});

  @override
  ConsumerState<CollageView> createState() => _CollageViewState();
}

class _CollageViewState extends ConsumerState<CollageView> {
  final _picker = ImagePicker();
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  Uint8List? _preview;
  Timer? _debounce;
  int _renderId = 0;

  @override
  void initState() {
    super.initState();
    final spec = ref.read(collageProvider).spec;
    _title = TextEditingController(text: spec.title);
    _subtitle = TextEditingController(text: spec.subtitle);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleRender());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _title.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  void _scheduleRender() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), _render);
  }

  Future<void> _render() async {
    final st = ref.read(collageProvider);
    if (st.sources.isEmpty) {
      if (mounted) setState(() => _preview = null);
      return;
    }
    final id = ++_renderId;
    final images = [for (final p in st.used) await decodeCollageImage(p.bytes)];
    final png = await renderCollage(st.effective, images, outWidth: 720);
    if (!mounted || id != _renderId) return;
    setState(() => _preview = png);
  }

  Future<void> _addPhotos() async {
    final ctrl = ref.read(collageProvider.notifier);
    final files = await _picker.pickMultiImage();
    if (files.isEmpty || !mounted) return;
    await ctrl.add([for (final f in files) await f.readAsBytes()]);
  }

  Future<void> _photoActions(int i) async {
    final l = AppLocalizations.of(context);
    final ctrl = ref.read(collageProvider.notifier);
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 'replace'),
            child: Text(l.replace),
          ),
          if (i > 0)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, 'earlier'),
              child: Text(l.moveEarlier),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, 'remove'),
            child: Text(l.remove),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
      ),
    );
    switch (action) {
      case 'replace':
        final f = await _picker.pickImage(source: ImageSource.gallery);
        if (f != null) await ctrl.replaceAt(i, await f.readAsBytes());
      case 'earlier':
        ctrl.moveEarlier(i);
      case 'remove':
        ctrl.removeAt(i);
    }
  }

  Future<void> _create() async {
    HapticFeedback.mediumImpact();
    try {
      final png = await ref.read(collageProvider.notifier).export();
      if (!mounted) return;
      await Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute<void>(
          builder: (ctx) =>
              ResultPage(result: png, onTweak: () => Navigator.of(ctx).pop()),
        ),
      );
    } catch (e) {
      if (mounted) showInfoDialog(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final st = ref.watch(collageProvider);
    final ctrl = ref.read(collageProvider.notifier);
    final spec = st.spec;
    final eff = st.effective;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    ref.listen(collageProvider, (prev, next) {
      if (prev?.sources != next.sources || prev?.spec != next.spec) {
        _scheduleRender();
      }
      // A collage loaded from History replaces what the fields show.
      if (next.spec.title != _title.text) _title.text = next.spec.title;
      if (next.spec.subtitle != _subtitle.text) {
        _subtitle.text = next.spec.subtitle;
      }
      if (next.imageError && !(prev?.imageError ?? false)) {
        showInfoDialog(context, l.errImageTitle);
      }
    });

    final hasText = spec.style != CollageStyle.moments;
    return CupertinoPageScaffold(
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: Text(l.modeCollage),
                  automaticallyImplyLeading: false,
                  leading: WorkspaceBack(enabled: !st.busy),
                ),
                SliverSafeArea(
                  top: false,
                  sliver: SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    sliver: SliverList.list(
                      children: [
                        if (st.sources.isEmpty)
                          _Empty(
                            title: l.collageEmptyTitle,
                            hint: l.collageEmptyHint,
                            button: l.collageAddPhotos,
                            busy: st.busy,
                            onPressed: _addPhotos,
                          )
                        else ...[
                          _Preview(
                            bytes: _preview,
                            aspect: _aspect(spec),
                            spec: eff,
                            photos: st.used,
                            onSwap: ctrl.swap,
                          ),
                          _Note(l.collageDragHint, false),
                          const SizedBox(height: 16),
                          _Strip(
                            photos: st.sources,
                            slots: eff.layout.slots,
                            busy: st.busy,
                            onAdd: _addPhotos,
                            onTap: _photoActions,
                          ),
                          if (st.missing > 0)
                            _Note(l.collageNeedMore(st.missing), true)
                          else if (st.sources.length > eff.layout.slots)
                            _Note(l.collageExtraUnused, false),
                          _Label(l.collageLayout),
                          _LayoutRow(
                            auto: spec.auto,
                            selected: eff.layout,
                            isZh: isZh,
                            smartLabel: l.collageSmart,
                            onSmart: () =>
                                ctrl.setSpec(spec.copyWith(auto: true)),
                            onPick: (v) => ctrl.setSpec(
                              spec.copyWith(auto: false, layout: v),
                            ),
                          ),
                          _Label(l.collageStyle),
                          _StyleRow(
                            selected: spec.style,
                            isZh: isZh,
                            onPick: (v) =>
                                ctrl.setSpec(spec.copyWith(style: v)),
                          ),
                          if (hasText) ...[
                            const SizedBox(height: 16),
                            _Field(
                              controller: _title,
                              placeholder: l.collageTitleHint,
                              onChanged: (v) =>
                                  ctrl.setSpec(spec.copyWith(title: v)),
                            ),
                            const SizedBox(height: 8),
                            _Field(
                              controller: _subtitle,
                              placeholder: l.collageSubtitleHint,
                              onChanged: (v) =>
                                  ctrl.setSpec(spec.copyWith(subtitle: v)),
                            ),
                          ],
                          if (spec.style == CollageStyle.custom)
                            _CustomControls(
                              spec: spec,
                              l: l,
                              onChanged: ctrl.setSpec,
                            ),
                          const SizedBox(height: 4),
                          Text(
                            '${st.sources.length}/$kCollageMaxPhotos',
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 12, color: secondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (st.sources.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(14),
                    onPressed: st.busy || st.missing > 0 ? null : _create,
                    child: st.busy
                        ? const CupertinoActivityIndicator()
                        : Text(l.collageCreate),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _aspect(CollageSpec s) {
    switch (s.style) {
      case CollageStyle.moments:
        return 1;
      case CollageStyle.custom:
        final r = kCollageRatios[s.ratio];
        return r.$2 / r.$3;
      case CollageStyle.xiaohongshu:
      case CollageStyle.editorial:
      case CollageStyle.swiss:
        return 3 / 4;
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.title,
    required this.hint,
    required this.button,
    required this.busy,
    required this.onPressed,
  });

  final String title, hint, button;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Icon(CupertinoIcons.square_grid_2x2, size: 72, color: secondary),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: secondary),
          ),
          const SizedBox(height: 28),
          CupertinoButton.filled(
            borderRadius: BorderRadius.circular(14),
            onPressed: busy ? null : onPressed,
            child: busy ? const CupertinoActivityIndicator() : Text(button),
          ),
        ],
      ),
    );
  }
}

/// The rendered collage. Long-press a photo and drag it onto another cell to
/// swap their positions.
class _Preview extends StatefulWidget {
  const _Preview({
    required this.bytes,
    required this.aspect,
    required this.spec,
    required this.photos,
    required this.onSwap,
  });

  final Uint8List? bytes;
  final double aspect;
  final CollageSpec spec;
  final List<CollagePhoto> photos;
  final void Function(int from, int to) onSwap;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  int? _from, _over;
  Offset? _pos;
  String? _cellsKey;
  ({Size size, List<Rect> rects})? _cells;

  ({Size size, List<Rect> rects}) get _geometry {
    final key = widget.spec.toJson().toString();
    if (key != _cellsKey) {
      _cellsKey = key;
      _cells = collageCells(widget.spec);
    }
    return _cells!;
  }

  int? _hit(Offset local, double scale) {
    final p = local / scale;
    final rects = _geometry.rects;
    for (var i = 0; i < rects.length && i < widget.photos.length; i++) {
      if (rects[i].contains(p)) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.5;
    final blue = CupertinoTheme.of(context).primaryColor;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: AspectRatio(
          aspectRatio: widget.aspect,
          child: LayoutBuilder(
            builder: (context, box) {
              final g = _geometry;
              final scale = box.maxWidth / g.size.width;
              Rect shown(int i) => Rect.fromLTWH(
                g.rects[i].left * scale,
                g.rects[i].top * scale,
                g.rects[i].width * scale,
                g.rects[i].height * scale,
              );
              return GestureDetector(
                onLongPressStart: (d) {
                  final i = _hit(d.localPosition, scale);
                  if (i == null) return;
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _from = i;
                    _over = i;
                    _pos = d.localPosition;
                  });
                },
                onLongPressMoveUpdate: (d) {
                  if (_from == null) return;
                  setState(() {
                    _pos = d.localPosition;
                    _over = _hit(d.localPosition, scale) ?? _over;
                  });
                },
                onLongPressEnd: (_) {
                  final from = _from, to = _over;
                  setState(() => _from = _over = _pos = null);
                  if (from != null && to != null && from != to) {
                    HapticFeedback.selectionClick();
                    widget.onSwap(from, to);
                  }
                },
                onLongPressCancel: () =>
                    setState(() => _from = _over = _pos = null),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemGroupedBackground
                        .resolveFrom(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (widget.bytes == null)
                          const Center(child: CupertinoActivityIndicator())
                        else
                          Image.memory(
                            widget.bytes!,
                            fit: BoxFit.fill,
                            gaplessPlayback: true,
                          ),
                        if (_from != null) ...[
                          Positioned.fromRect(
                            rect: shown(_from!),
                            child: const ColoredBox(color: Color(0x66000000)),
                          ),
                          if (_over != null && _over != _from)
                            Positioned.fromRect(
                              rect: shown(_over!),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(color: blue, width: 3),
                                  color: blue.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                          if (_pos != null)
                            Positioned(
                              left: _pos!.dx - 36,
                              top: _pos!.dy - 36,
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: 0.85,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      widget.photos[_from!].bytes,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                      cacheWidth: 216,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({
    required this.photos,
    required this.slots,
    required this.busy,
    required this.onAdd,
    required this.onTap,
  });

  final List<CollagePhoto> photos;
  final int slots;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final fill = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
      context,
    );
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length + (photos.length < kCollageMaxPhotos ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == photos.length) {
            return GestureDetector(
              onTap: busy ? null : onAdd,
              child: Container(
                width: 64,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: busy
                    ? const CupertinoActivityIndicator()
                    : const Icon(CupertinoIcons.add),
              ),
            );
          }
          return GestureDetector(
            onTap: () => onTap(i),
            child: Opacity(
              opacity: i < slots ? 1 : 0.35,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      photos[i].bytes,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      cacheWidth: 192,
                    ),
                  ),
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: const Color(0x99000000),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text, this.warn);
  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: warn
            ? CupertinoColors.systemOrange.resolveFrom(context)
            : CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.selected,
    required this.onTap,
    required this.child,
  });
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final blue = CupertinoTheme.of(context).primaryColor;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? blue.withValues(alpha: 0.14)
              : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
                  context,
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? blue : const Color(0x00000000),
            width: 1.5,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _LayoutRow extends StatelessWidget {
  const _LayoutRow({
    required this.auto,
    required this.selected,
    required this.isZh,
    required this.smartLabel,
    required this.onSmart,
    required this.onPick,
  });

  final bool auto;
  final CollageLayout selected;
  final bool isZh;
  final String smartLabel;
  final VoidCallback onSmart;
  final ValueChanged<CollageLayout> onPick;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 76,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: CollageLayout.values.length + 1,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        if (i == 0) {
          return _Pill(
            selected: auto,
            onTap: onSmart,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 28,
                  child: Icon(CupertinoIcons.sparkles, size: 24),
                ),
                const SizedBox(height: 4),
                Text(smartLabel, style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        }
        final v = CollageLayout.values[i - 1];
        return _Pill(
          selected: !auto && v == selected,
          onTap: () => onPick(v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(28, 28),
                painter: _LayoutIcon(
                  v,
                  CupertinoColors.label.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(v.label(isZh), style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      },
    ),
  );
}

class _LayoutIcon extends CustomPainter {
  const _LayoutIcon(this.layout, this.color);
  final CollageLayout layout;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.75);
    for (final r in layout.rects(Offset.zero & size, 2)) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(1.5)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LayoutIcon old) =>
      old.layout != layout || old.color != color;
}

class _StyleRow extends StatelessWidget {
  const _StyleRow({
    required this.selected,
    required this.isZh,
    required this.onPick,
  });

  final CollageStyle selected;
  final bool isZh;
  final ValueChanged<CollageStyle> onPick;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: CollageStyle.values.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final v = CollageStyle.values[i];
        return _Pill(
          selected: v == selected,
          onTap: () => onPick(v),
          child: Text(v.label(isZh), style: const TextStyle(fontSize: 14)),
        );
      },
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.placeholder,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => CupertinoTextField(
    controller: controller,
    placeholder: placeholder,
    maxLength: 40,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
        context,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    onChanged: onChanged,
  );
}

class _CustomControls extends StatelessWidget {
  const _CustomControls({
    required this.spec,
    required this.l,
    required this.onChanged,
  });

  final CollageSpec spec;
  final AppLocalizations l;
  final ValueChanged<CollageSpec> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Label(l.collageRatio),
      CupertinoSlidingSegmentedControl<int>(
        groupValue: spec.ratio,
        children: {
          for (var i = 0; i < kCollageRatios.length; i++)
            i: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(kCollageRatios[i].$1),
            ),
        },
        onValueChanged: (v) {
          if (v != null) onChanged(spec.copyWith(ratio: v));
        },
      ),
      _Label(l.collageBackground),
      Row(
        children: [
          for (final c in kCollageColors)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => onChanged(spec.copyWith(background: c)),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: spec.background == c
                          ? CupertinoTheme.of(context).primaryColor
                          : CupertinoColors.separator.resolveFrom(context),
                      width: spec.background == c ? 2.5 : 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      _Label(l.collageGap),
      CupertinoSlider(
        value: spec.gap,
        min: 0,
        max: 40,
        onChanged: (v) => onChanged(spec.copyWith(gap: v)),
      ),
      _Label(l.collageRadius),
      CupertinoSlider(
        value: spec.radius,
        min: 0,
        max: 60,
        onChanged: (v) => onChanged(spec.copyWith(radius: v)),
      ),
    ],
  );
}
