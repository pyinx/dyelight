import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'collage_spec.dart';

/// Logical canvas width; every metric below is in these units.
const double kCollageBase = 1080;

const _sans = ['PingFang SC', 'Noto Sans CJK SC', 'Roboto', 'Helvetica'];
const _serif = ['Songti SC', 'Noto Serif CJK SC', 'Times New Roman', 'serif'];
const _mono = ['Menlo', 'Roboto Mono', 'Courier', 'monospace'];

final _decoded = Expando<ui.Image>('collage-decoded');

/// Decodes once per byte buffer; re-renders while editing reuse the result.
Future<ui.Image> decodeCollageImage(Uint8List bytes) async {
  final hit = _decoded[bytes];
  if (hit != null) return hit;
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  codec.dispose();
  return _decoded[bytes] = frame.image;
}

class _Look {
  const _Look({
    required this.w,
    required this.h,
    required this.bg,
    required this.ink,
    required this.accent,
    required this.pad,
    required this.gap,
    required this.radius,
  });
  final double w, h, pad, gap, radius;
  final Color bg, ink, accent;
}

_Look _lookFor(CollageSpec s) {
  const w = kCollageBase;
  switch (s.style) {
    case CollageStyle.xiaohongshu:
      return const _Look(
        w: w,
        h: 1440,
        bg: Color(0xFFFFF8F2),
        ink: Color(0xFF222222),
        accent: Color(0xFFFF2442),
        pad: 48,
        gap: 16,
        radius: 28,
      );
    case CollageStyle.moments:
      return const _Look(
        w: w,
        h: 1080,
        bg: Color(0xFFFFFFFF),
        ink: Color(0xFF222222),
        accent: Color(0xFF07C160),
        pad: 0,
        gap: 6,
        radius: 0,
      );
    case CollageStyle.editorial:
      return const _Look(
        w: w,
        h: 1440,
        bg: Color(0xFFF3EEE3),
        ink: Color(0xFF1B1A17),
        accent: Color(0xFF8A6D3B),
        pad: 72,
        gap: 18,
        radius: 0,
      );
    case CollageStyle.swiss:
      return const _Look(
        w: w,
        h: 1440,
        bg: Color(0xFFFFFFFF),
        ink: Color(0xFF111111),
        accent: Color(0xFFE10600),
        pad: 60,
        gap: 12,
        radius: 0,
      );
    case CollageStyle.custom:
      final bg = Color(s.background);
      final r = kCollageRatios[s.ratio.clamp(0, kCollageRatios.length - 1)];
      return _Look(
        w: w,
        h: w * r.$3 / r.$2,
        bg: bg,
        ink: bg.computeLuminance() > 0.45
            ? const Color(0xFF222222)
            : const Color(0xFFF5F5F5),
        accent: const Color(0xFF0A84FF),
        pad: 48,
        gap: s.gap,
        radius: s.radius,
      );
  }
}

TextPainter _text(
  String t,
  double size,
  Color color, {
  required double width,
  FontWeight weight = FontWeight.w400,
  List<String> fonts = _sans,
  double spacing = 0,
  double height = 1.25,
  int? maxLines,
}) => TextPainter(
  text: TextSpan(
    text: t,
    style: TextStyle(
      fontFamily: fonts.first,
      fontFamilyFallback: fonts.sublist(1),
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: height,
    ),
  ),
  textDirection: TextDirection.ltr,
  maxLines: maxLines,
  ellipsis: '…',
)..layout(maxWidth: width);

({_Look look, List<Rect> rects}) _layout(
  CollageSpec spec,
  Canvas canvas,
  DateTime? now,
) {
  final look = _lookFor(spec);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, look.w, look.h),
    Paint()..color = look.bg,
  );
  final hasText =
      spec.style != CollageStyle.moments &&
      (spec.title.isNotEmpty || spec.subtitle.isNotEmpty);
  final inner = look.w - look.pad * 2;
  var top = look.pad;
  var bottom = look.h - look.pad;
  if (hasText) top = _header(canvas, spec, look, top, inner);
  if (spec.style == CollageStyle.editorial) {
    bottom = _editorialFooter(canvas, look, bottom, inner, now);
  }
  final area = Rect.fromLTRB(look.pad, top, look.pad + inner, bottom);
  return (look: look, rects: spec.layout.rects(area, look.gap));
}

/// Cell rectangles (and the canvas size) exactly as [renderCollage] places
/// them, for hit-testing drags on the preview.
({Size size, List<Rect> rects}) collageCells(CollageSpec spec) {
  final recorder = ui.PictureRecorder();
  final l = _layout(spec, ui.Canvas(recorder), null);
  recorder.endRecording().dispose();
  return (size: Size(l.look.w, l.look.h), rects: l.rects);
}

/// Composes [sources] into one PNG. Cells without a source stay empty.
/// [outWidth] only scales the output; the design is fixed at 1080 wide.
Future<Uint8List> renderCollage(
  CollageSpec spec,
  List<ui.Image> sources, {
  double outWidth = kCollageBase,
  DateTime? now,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  // The scale must be set before anything is drawn, so size comes first.
  final scale = outWidth / kCollageBase;
  canvas.scale(scale);
  final planned = _layout(spec, canvas, now);
  final look = planned.look;
  final rects = planned.rects;
  final placeholder = Paint()..color = look.ink.withValues(alpha: 0.08);
  for (var i = 0; i < rects.length; i++) {
    final r = rects[i];
    final rr = RRect.fromRectAndRadius(r, Radius.circular(look.radius));
    if (i >= sources.length) {
      canvas.drawRRect(rr, placeholder);
      continue;
    }
    final img = sources[i];
    canvas
      ..save()
      ..clipRRect(rr, doAntiAlias: true);
    canvas.drawImageRect(
      img,
      _coverSrc(img, r),
      r,
      Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true,
    );
    canvas.restore();
    if (spec.style == CollageStyle.swiss) _swissIndex(canvas, look, r, i + 1);
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(
    outWidth.round(),
    (look.h * scale).round(),
  );
  picture.dispose();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Centered crop of [img] that fills [dst] without distortion.
Rect _coverSrc(ui.Image img, Rect dst) {
  final iw = img.width.toDouble(), ih = img.height.toDouble();
  final target = dst.width / dst.height;
  if (iw / ih > target) {
    final w = ih * target;
    return Rect.fromLTWH((iw - w) / 2, 0, w, ih);
  }
  final h = iw / target;
  return Rect.fromLTWH(0, (ih - h) / 2, iw, h);
}

/// Draws the title block and returns the y where the grid may start.
double _header(
  Canvas canvas,
  CollageSpec s,
  _Look look,
  double top,
  double width,
) {
  final x = look.pad;
  var y = top;
  final gapAfter = look.gap + 20;
  switch (s.style) {
    case CollageStyle.editorial:
      canvas.drawRect(Rect.fromLTWH(x, y, width, 3), Paint()..color = look.ink);
      y += 22;
      if (s.subtitle.isNotEmpty) {
        final sub = _text(
          s.subtitle.toUpperCase(),
          24,
          look.accent,
          width: width,
          spacing: 5,
          maxLines: 1,
        );
        sub.paint(canvas, Offset(x, y));
        y += sub.height + 12;
      }
      if (s.title.isNotEmpty) {
        final t = _text(
          s.title,
          88,
          look.ink,
          width: width,
          weight: FontWeight.w300,
          fonts: _serif,
          height: 1.15,
          maxLines: 2,
        );
        t.paint(canvas, Offset(x, y));
        y += t.height;
      }
      return y + gapAfter;
    case CollageStyle.swiss:
      canvas.drawRect(
        Rect.fromLTWH(x, y, 28, 28),
        Paint()..color = look.accent,
      );
      y += 44;
      if (s.title.isNotEmpty) {
        final t = _text(
          s.title,
          92,
          look.ink,
          width: width,
          weight: FontWeight.w300,
          height: 1.08,
          maxLines: 2,
        );
        t.paint(canvas, Offset(x, y));
        y += t.height + 8;
      }
      if (s.subtitle.isNotEmpty) {
        final sub = _text(
          s.subtitle,
          26,
          look.ink.withValues(alpha: 0.6),
          width: width,
          fonts: _mono,
          maxLines: 1,
        );
        sub.paint(canvas, Offset(x, y));
        y += sub.height + 8;
      }
      canvas.drawRect(
        Rect.fromLTWH(x, y + 6, width, 2),
        Paint()..color = look.ink,
      );
      return y + 6 + gapAfter;
    case CollageStyle.xiaohongshu:
    case CollageStyle.custom:
    case CollageStyle.moments:
      if (s.title.isNotEmpty) {
        final t = _text(
          s.title,
          s.style == CollageStyle.xiaohongshu ? 84 : 72,
          look.ink,
          width: width,
          weight: FontWeight.w800,
          height: 1.2,
          maxLines: 2,
        );
        if (s.style == CollageStyle.xiaohongshu) {
          // Highlighter stripe behind the lower part of each line.
          final mark = Paint()..color = look.accent.withValues(alpha: 0.28);
          for (final m in t.computeLineMetrics()) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(
                  x,
                  y + m.baseline - m.ascent * 0.35,
                  m.width,
                  m.height * 0.4,
                ),
                const Radius.circular(8),
              ),
              mark,
            );
          }
        }
        t.paint(canvas, Offset(x, y));
        y += t.height + 8;
      }
      if (s.subtitle.isNotEmpty) {
        final sub = _text(
          s.subtitle,
          34,
          look.ink.withValues(alpha: 0.55),
          width: width,
          maxLines: 2,
        );
        sub.paint(canvas, Offset(x, y));
        y += sub.height;
      }
      return y + gapAfter;
  }
}

double _editorialFooter(
  Canvas canvas,
  _Look look,
  double bottom,
  double width,
  DateTime? now,
) {
  final d = now ?? DateTime.now();
  final date =
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  final left = _text(
    date,
    22,
    look.ink.withValues(alpha: 0.6),
    width: width / 2,
    fonts: _mono,
    spacing: 2,
    maxLines: 1,
  );
  final right = _text(
    'DYELIGHT',
    22,
    look.ink.withValues(alpha: 0.6),
    width: width / 2,
    spacing: 6,
    maxLines: 1,
  );
  final y = bottom - left.height;
  left.paint(canvas, Offset(look.pad, y));
  right.paint(canvas, Offset(look.pad + width - right.width, y));
  canvas.drawRect(
    Rect.fromLTWH(look.pad, y - 14, width, 1.5),
    Paint()..color = look.ink.withValues(alpha: 0.5),
  );
  return y - 14 - look.gap - 10;
}

void _swissIndex(Canvas canvas, _Look look, Rect cell, int n) {
  final t = _text(
    n.toString().padLeft(2, '0'),
    22,
    look.ink,
    width: 80,
    fonts: _mono,
    maxLines: 1,
  );
  final chip = Rect.fromLTWH(
    cell.left,
    cell.top,
    math.min(t.width + 20, cell.width),
    t.height + 12,
  );
  canvas.drawRect(chip, Paint()..color = look.bg);
  t.paint(canvas, Offset(chip.left + 10, chip.top + 6));
}
