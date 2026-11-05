import 'dart:ui';

/// One cell of a layout, in grid units.
class GridCell {
  const GridCell(this.col, this.row, [this.colSpan = 1, this.rowSpan = 1]);
  final int col, row, colSpan, rowSpan;
}

enum CollageLayout {
  single(1, 1, [GridCell(0, 0)], '单图', 'Single'),
  leftRight(2, 1, [GridCell(0, 0), GridCell(1, 0)], '左右', 'Side by side'),
  topBottom(1, 2, [GridCell(0, 0), GridCell(0, 1)], '上下', 'Stacked'),
  threeCols(
    3,
    1,
    [GridCell(0, 0), GridCell(1, 0), GridCell(2, 0)],
    '三联',
    'Triptych',
  ),
  bigLeft(
    2,
    2,
    [GridCell(0, 0, 1, 2), GridCell(1, 0), GridCell(1, 1)],
    '一大两小',
    'Hero + 2',
  ),
  bigTop(
    2,
    2,
    [GridCell(0, 0, 2), GridCell(0, 1), GridCell(1, 1)],
    '上大下二',
    'Banner + 2',
  ),
  hero4(
    2,
    3,
    [
      GridCell(0, 0, 2),
      GridCell(0, 1),
      GridCell(1, 1),
      GridCell(0, 2),
      GridCell(1, 2),
    ],
    '一大四小',
    'Hero + 4',
  ),
  grid4(
    2,
    2,
    [GridCell(0, 0), GridCell(1, 0), GridCell(0, 1), GridCell(1, 1)],
    '四宫格',
    '2×2',
  ),
  grid6(
    2,
    3,
    [
      GridCell(0, 0),
      GridCell(1, 0),
      GridCell(0, 1),
      GridCell(1, 1),
      GridCell(0, 2),
      GridCell(1, 2),
    ],
    '六宫格',
    '2×3',
  ),
  hero6(
    3,
    3,
    [
      GridCell(0, 0, 3),
      GridCell(0, 1),
      GridCell(1, 1),
      GridCell(2, 1),
      GridCell(0, 2),
      GridCell(1, 2),
      GridCell(2, 2),
    ],
    '一大六小',
    'Hero + 6',
  ),
  grid8(
    4,
    2,
    [
      GridCell(0, 0),
      GridCell(1, 0),
      GridCell(2, 0),
      GridCell(3, 0),
      GridCell(0, 1),
      GridCell(1, 1),
      GridCell(2, 1),
      GridCell(3, 1),
    ],
    '八宫格',
    '4×2',
  ),
  grid9(
    3,
    3,
    [
      GridCell(0, 0),
      GridCell(1, 0),
      GridCell(2, 0),
      GridCell(0, 1),
      GridCell(1, 1),
      GridCell(2, 1),
      GridCell(0, 2),
      GridCell(1, 2),
      GridCell(2, 2),
    ],
    '九宫格',
    '3×3',
  );

  const CollageLayout(this.cols, this.rows, this.cells, this.zh, this.en);
  final int cols, rows;
  final List<GridCell> cells;
  final String zh, en;

  int get slots => cells.length;

  String label(bool isZh) => isZh ? zh : en;

  /// Cell rectangles inside [area], separated by [gap].
  List<Rect> rects(Rect area, double gap) {
    final cw = (area.width - gap * (cols - 1)) / cols;
    final ch = (area.height - gap * (rows - 1)) / rows;
    return [
      for (final c in cells)
        Rect.fromLTWH(
          area.left + c.col * (cw + gap),
          area.top + c.row * (ch + gap),
          cw * c.colSpan + gap * (c.colSpan - 1),
          ch * c.rowSpan + gap * (c.rowSpan - 1),
        ),
    ];
  }
}

/// Picks a layout that fits [sizes].length photos (1–9) and their shapes.
CollageLayout smartLayout(List<Size> sizes) {
  final n = sizes.length;
  bool portrait(Size s) => s.height > s.width;
  final portraits = sizes.where(portrait).length;
  switch (n) {
    case <= 1:
      return CollageLayout.single;
    case 2:
      // Two wide photos stack; anything else sits side by side.
      return portraits == 0 ? CollageLayout.topBottom : CollageLayout.leftRight;
    case 3:
      if (portraits == 3) return CollageLayout.threeCols;
      return portrait(sizes.first)
          ? CollageLayout.bigLeft
          : CollageLayout.bigTop;
    case 4:
      return CollageLayout.grid4;
    case 5:
      return CollageLayout.hero4;
    case 6:
      return CollageLayout.grid6;
    case 7:
      return CollageLayout.hero6;
    case 8:
      return CollageLayout.grid8;
    default:
      return CollageLayout.grid9;
  }
}

enum CollageStyle {
  xiaohongshu('小红书', 'Xiaohongshu'),
  moments('朋友圈', 'Moments'),
  editorial('杂志', 'Editorial'),
  swiss('瑞士', 'Swiss'),
  custom('自定义', 'Custom');

  const CollageStyle(this.zh, this.en);
  final String zh, en;
  String label(bool isZh) => isZh ? zh : en;
}

/// Canvas ratios (width : height) offered by the custom style.
const kCollageRatios = <(String, double, double)>[
  ('3:4', 3, 4),
  ('1:1', 1, 1),
  ('4:5', 4, 5),
  ('9:16', 9, 16),
];

/// Background swatches offered by the custom style (ARGB).
const kCollageColors = <int>[
  0xFFFFFFFF,
  0xFFF3EEE3,
  0xFFFFE4E1,
  0xFFDDE8F5,
  0xFF1B1A17,
];

class CollageSpec {
  const CollageSpec({
    this.auto = true,
    this.layout = CollageLayout.grid4,
    this.style = CollageStyle.xiaohongshu,
    this.title = '',
    this.subtitle = '',
    this.ratio = 0,
    this.background = 0xFFFFFFFF,
    this.gap = 12,
    this.radius = 24,
  });

  /// Smart mode: the layout follows the photos instead of [layout].
  final bool auto;
  final CollageLayout layout;
  final CollageStyle style;
  final String title;
  final String subtitle;

  /// Index into [kCollageRatios]; only used by [CollageStyle.custom].
  final int ratio;

  /// Only used by [CollageStyle.custom].
  final int background;

  /// Custom style only, in pixels of a 1080-wide canvas.
  final double gap;
  final double radius;

  CollageSpec copyWith({
    bool? auto,
    CollageLayout? layout,
    CollageStyle? style,
    String? title,
    String? subtitle,
    int? ratio,
    int? background,
    double? gap,
    double? radius,
  }) => CollageSpec(
    auto: auto ?? this.auto,
    layout: layout ?? this.layout,
    style: style ?? this.style,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    ratio: ratio ?? this.ratio,
    background: background ?? this.background,
    gap: gap ?? this.gap,
    radius: radius ?? this.radius,
  );

  Map<String, dynamic> toJson() => {
    'auto': auto,
    'layout': layout.name,
    'style': style.name,
    'title': title,
    'subtitle': subtitle,
    'ratio': ratio,
    'background': background,
    'gap': gap,
    'radius': radius,
  };

  factory CollageSpec.fromJson(Map<dynamic, dynamic> j) {
    const d = CollageSpec();
    return CollageSpec(
      // Saved before smart mode existed: keep the layout the user picked.
      auto: j['auto'] as bool? ?? false,
      layout:
          CollageLayout.values
              .where((e) => e.name == j['layout'])
              .firstOrNull ??
          d.layout,
      style:
          CollageStyle.values.where((e) => e.name == j['style']).firstOrNull ??
          d.style,
      title: j['title'] as String? ?? '',
      subtitle: j['subtitle'] as String? ?? '',
      ratio: ((j['ratio'] as int?) ?? 0).clamp(0, kCollageRatios.length - 1),
      background: j['background'] as int? ?? d.background,
      gap: (j['gap'] as num?)?.toDouble() ?? d.gap,
      radius: (j['radius'] as num?)?.toDouble() ?? d.radius,
    );
  }
}
