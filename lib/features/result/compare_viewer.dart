import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

const double kMaxZoom = 6;

/// Split-screen before/after viewer.
///
/// Both images are drawn through one shared [TransformationController], so
/// pinch-zoom and pan are identical on both sides. The divider lives in screen
/// space; only the divider and the clipper listen to its [ValueNotifier], so
/// dragging never rebuilds the image layers.
class CompareViewer extends StatefulWidget {
  const CompareViewer({
    super.key,
    required this.original,
    required this.result,
    this.onTap,
    this.originalLabel = '',
    this.resultLabel = '',
  });

  final Uint8List original;
  final Uint8List result;
  final VoidCallback? onTap;
  final String originalLabel;
  final String resultLabel;

  @override
  State<CompareViewer> createState() => _CompareViewerState();
}

class _CompareViewerState extends State<CompareViewer> {
  final _transform = TransformationController();
  final _split = ValueNotifier<double>(0.5);
  final _holdOriginal = ValueNotifier<bool>(false);

  late final MemoryImage _origRaw = MemoryImage(widget.original);
  late final MemoryImage _resRaw = MemoryImage(widget.result);

  Matrix4 _startMatrix = Matrix4.identity();
  Offset _startFocal = Offset.zero;
  Size _size = Size.zero;

  @override
  void dispose() {
    // Free decoded textures when leaving the compare view.
    _origRaw.evict();
    _resRaw.evict();
    PaintingBinding.instance.imageCache.clearLiveImages();
    _transform.dispose();
    _split.dispose();
    _holdOriginal.dispose();
    super.dispose();
  }

  void _setSplit(double v) {
    final old = _split.value;
    final next = v.clamp(0.0, 1.0);
    if ((old - 0.5) * (next - 0.5) < 0) HapticFeedback.lightImpact();
    _split.value = next;
  }

  void _onScaleStart(ScaleStartDetails d) {
    _startMatrix = _transform.value.clone();
    _startFocal = d.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final m = Matrix4.identity()
      ..translateByDouble(d.localFocalPoint.dx, d.localFocalPoint.dy, 0, 1)
      ..scaleByDouble(d.scale, d.scale, 1, 1)
      ..translateByDouble(-_startFocal.dx, -_startFocal.dy, 0, 1);
    final next = m * _startMatrix;
    final s = next.storage[0].clamp(1.0, kMaxZoom);
    next.storage[0] = s;
    next.storage[5] = s;
    // Keep the content covering the viewport.
    next.storage[12] = next.storage[12].clamp(_size.width * (1 - s), 0.0);
    next.storage[13] = next.storage[13].clamp(_size.height * (1 - s), 0.0);
    _transform.value = next;
  }

  Widget _layer(ImageProvider raw, int cacheWidth) => AnimatedBuilder(
    animation: _transform,
    builder: (_, child) => Transform(transform: _transform.value, child: child),
    child: SizedBox.expand(
      child: Image(
        image: ResizeImage(raw, width: cacheWidth),
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        _size = c.biggest;
        // 2x headroom for zoom, bounded to avoid huge textures.
        final cacheWidth = (c.maxWidth * dpr * 2).clamp(512, 3072).round();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onDoubleTap: () => _transform.value = Matrix4.identity(),
          onLongPressStart: (_) {
            HapticFeedback.selectionClick();
            _holdOriginal.value = true;
          },
          onLongPressEnd: (_) => _holdOriginal.value = false,
          onLongPressCancel: () => _holdOriginal.value = false,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _layer(_resRaw, cacheWidth),
                ClipRect(
                  clipper: _SplitClipper(_split, _holdOriginal),
                  child: _layer(_origRaw, cacheWidth),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _DividerPainter(_split, _holdOriginal),
                    ),
                  ),
                ),
                _Handle(
                  split: _split,
                  hold: _holdOriginal,
                  width: c.maxWidth,
                  onChanged: _setSplit,
                ),
                Positioned(
                  left: 16,
                  top: MediaQuery.paddingOf(context).top + 56,
                  child: _Tag(widget.originalLabel),
                ),
                Positioned(
                  right: 16,
                  top: MediaQuery.paddingOf(context).top + 56,
                  child: _Tag(widget.resultLabel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SplitClipper extends CustomClipper<Rect> {
  _SplitClipper(this.split, this.hold)
    : super(reclip: Listenable.merge([split, hold]));
  final ValueNotifier<double> split;
  final ValueNotifier<bool> hold;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(
    0,
    0,
    size.width * (hold.value ? 1 : split.value),
    size.height,
  );

  @override
  bool shouldReclip(_SplitClipper old) =>
      old.split != split || old.hold != hold;
}

class _DividerPainter extends CustomPainter {
  _DividerPainter(this.split, this.hold)
    : super(repaint: Listenable.merge([split, hold]));
  final ValueNotifier<double> split;
  final ValueNotifier<bool> hold;

  @override
  void paint(Canvas canvas, Size size) {
    if (hold.value) return;
    final x = size.width * split.value;
    final line = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 2;
    canvas.drawShadow(
      Path()..addRect(Rect.fromLTWH(x - 1, 0, 2, size.height)),
      const Color(0xFF000000),
      3,
      false,
    );
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    final c = Offset(x, size.height / 2);
    canvas.drawCircle(c, 20, Paint()..color = const Color(0xCCFFFFFF));
    final arrow = Paint()
      ..color = const Color(0xFF3A3A3C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(x - 4, c.dy - 6)
        ..lineTo(x - 10, c.dy)
        ..lineTo(x - 4, c.dy + 6)
        ..moveTo(x + 4, c.dy - 6)
        ..lineTo(x + 10, c.dy)
        ..lineTo(x + 4, c.dy + 6),
      arrow,
    );
  }

  @override
  bool shouldRepaint(_DividerPainter old) => false;
}

/// Wide invisible drag target following the divider; exposes slider semantics.
class _Handle extends StatelessWidget {
  const _Handle({
    required this.split,
    required this.hold,
    required this.width,
    required this.onChanged,
  });

  final ValueNotifier<double> split;
  final ValueNotifier<bool> hold;
  final double width;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: split,
      builder: (_, v, _) => Positioned(
        left: width * v - 28,
        top: 0,
        bottom: 0,
        width: 56,
        child: Semantics(
          slider: true,
          value: '${(v * 100).round()}%',
          increasedValue: '${((v + 0.1).clamp(0, 1) * 100).round()}%',
          decreasedValue: '${((v - 0.1).clamp(0, 1) * 100).round()}%',
          onIncrease: () => onChanged(v + 0.1),
          onDecrease: () => onChanged(v - 0.1),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (d) =>
                onChanged(split.value + d.delta.dx / width),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: const Color(0x66000000),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              text,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
