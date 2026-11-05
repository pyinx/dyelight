import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/image/preprocess.dart';
import '../features/collage/collage_renderer.dart';
import '../features/collage/collage_spec.dart';
import 'providers.dart';

enum CreateMode { recolor, collage }

/// null shows the Create home; otherwise the chosen workspace.
final createModeProvider = StateProvider<CreateMode?>((_) => null);

/// Lets other tabs jump back to Create (e.g. "adjust" from History).
final tabControllerProvider = Provider<CupertinoTabController>((ref) {
  final c = CupertinoTabController();
  ref.onDispose(c.dispose);
  return c;
});

const kCollageMaxPhotos = 9;
const _kCollageLongEdge = 1600;
const _kExportWidth = 1620.0;

class CollagePhoto {
  const CollagePhoto(this.bytes, this.width, this.height);
  final Uint8List bytes;
  final int width, height;
  Size get size => Size(width.toDouble(), height.toDouble());
}

class CollageState {
  const CollageState({
    this.sources = const [],
    this.spec = const CollageSpec(),
    this.busy = false,
    this.imageError = false,
  });

  final List<CollagePhoto> sources;
  final CollageSpec spec;
  final bool busy;
  final bool imageError;

  /// The spec to draw: in smart mode the layout follows the photos.
  CollageSpec get effective => spec.auto
      ? spec.copyWith(layout: smartLayout([for (final p in sources) p.size]))
      : spec;

  /// Photos that actually land in a cell.
  List<CollagePhoto> get used => sources.take(effective.layout.slots).toList();
  int get missing => effective.layout.slots - sources.length;

  CollageState copyWith({
    List<CollagePhoto>? sources,
    CollageSpec? spec,
    bool? busy,
    bool imageError = false,
  }) => CollageState(
    sources: sources ?? this.sources,
    spec: spec ?? this.spec,
    busy: busy ?? this.busy,
    imageError: imageError,
  );
}

class CollageController extends Notifier<CollageState> {
  @override
  CollageState build() => const CollageState();

  void setSpec(CollageSpec s) => state = state.copyWith(spec: s);

  /// Appends photos (preprocessed), up to [kCollageMaxPhotos].
  Future<void> add(List<Uint8List> raw) async {
    final room = kCollageMaxPhotos - state.sources.length;
    if (room <= 0 || raw.isEmpty) return;
    state = state.copyWith(busy: true);
    try {
      final out = <CollagePhoto>[];
      for (final r in raw.take(room)) {
        final p = await preprocessImage(r, maxLongEdge: _kCollageLongEdge);
        out.add(CollagePhoto(p.bytes, p.width, p.height));
      }
      state = state.copyWith(sources: [...state.sources, ...out], busy: false);
    } on FormatException {
      state = state.copyWith(busy: false, imageError: true);
    }
  }

  Future<void> replaceAt(int i, Uint8List raw) async {
    try {
      final p = await preprocessImage(raw, maxLongEdge: _kCollageLongEdge);
      final list = [...state.sources]
        ..[i] = CollagePhoto(p.bytes, p.width, p.height);
      state = state.copyWith(sources: list);
    } on FormatException {
      state = state.copyWith(imageError: true);
    }
  }

  void removeAt(int i) =>
      state = state.copyWith(sources: [...state.sources]..removeAt(i));

  void moveEarlier(int i) {
    if (i <= 0) return;
    final list = [...state.sources];
    list.insert(i - 1, list.removeAt(i));
    state = state.copyWith(sources: list);
  }

  /// Swaps two photos (drag-to-rearrange on the preview).
  void swap(int a, int b) {
    final list = [...state.sources];
    if (a == b || a >= list.length || b >= list.length) return;
    final t = list[a];
    list[a] = list[b];
    list[b] = t;
    state = state.copyWith(sources: list);
  }

  /// Loads a saved collage (already preprocessed) for further adjustment.
  Future<void> load(List<Uint8List> sources, CollageSpec spec) async {
    final photos = <CollagePhoto>[];
    for (final b in sources) {
      final img = await decodeCollageImage(b);
      photos.add(CollagePhoto(b, img.width, img.height));
    }
    state = CollageState(sources: photos, spec: spec);
  }

  /// Renders the export-size PNG and stores it in history.
  Future<Uint8List> export() async {
    state = state.copyWith(busy: true);
    try {
      final used = state.used;
      final spec = state.effective;
      final images = [for (final p in used) await decodeCollageImage(p.bytes)];
      final png = await renderCollage(spec, images, outWidth: _kExportWidth);
      await ref
          .read(historyRepoProvider)
          .addCollage(
            sources: [for (final p in used) p.bytes],
            result: png,
            spec: spec.toJson(),
            title: spec.title,
          );
      ref.read(historyProvider.notifier).refresh();
      return png;
    } finally {
      state = state.copyWith(busy: false);
    }
  }
}

final collageProvider = NotifierProvider<CollageController, CollageState>(
  CollageController.new,
);
