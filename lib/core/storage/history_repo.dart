import 'dart:io';
import 'dart:typed_data';

import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.createdAt,
    required this.prompt,
    required this.auto,
    required this.originalPath,
    required this.resultPath,
    this.sourcePaths = const [],
    this.spec,
    this.name = '',
  });

  final String id;
  final DateTime createdAt;
  final String prompt;
  final bool auto;
  final String originalPath;
  final String resultPath;

  /// Collage entries only: the photos placed in the collage, in order.
  final List<String> sourcePaths;

  /// Collage entries only: layout/style settings (see `CollageSpec.toJson`).
  final Map<String, dynamic>? spec;

  /// User-given title; empty falls back to the prompt/mode label.
  final String name;

  bool get isCollage => spec != null;

  HistoryEntry withName(String n) => HistoryEntry(
    id: id,
    createdAt: createdAt,
    prompt: prompt,
    auto: auto,
    originalPath: originalPath,
    resultPath: resultPath,
    sourcePaths: sourcePaths,
    spec: spec,
    name: n,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'prompt': prompt,
    'auto': auto,
    'originalPath': originalPath,
    'resultPath': resultPath,
    'sourcePaths': sourcePaths,
    'spec': spec,
    'name': name,
  };

  factory HistoryEntry.fromJson(Map<dynamic, dynamic> j) => HistoryEntry(
    id: j['id'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
    prompt: j['prompt'] as String? ?? '',
    auto: j['auto'] as bool? ?? false,
    originalPath: j['originalPath'] as String,
    resultPath: j['resultPath'] as String,
    sourcePaths: ((j['sourcePaths'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    spec: (j['spec'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)),
    name: j['name'] as String? ?? '',
  );
}

/// Metadata lives in Hive; images are files under [dir].
class HistoryRepo {
  HistoryRepo(this._box, this.dir);
  final Box<dynamic> _box;
  final Directory dir;

  /// Newest first.
  List<HistoryEntry> all() {
    final list =
        _box.values.whereType<Map>().map(HistoryEntry.fromJson).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<HistoryEntry> add({
    required Uint8List original,
    required Uint8List result,
    required String prompt,
    required bool auto,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await dir.create(recursive: true);
    final o = File(p.join(dir.path, '${id}_o.jpg'));
    final r = File(p.join(dir.path, '${id}_r.png'));
    await o.writeAsBytes(original);
    await r.writeAsBytes(result);
    final e = HistoryEntry(
      id: id,
      createdAt: DateTime.now(),
      prompt: prompt,
      auto: auto,
      originalPath: o.path,
      resultPath: r.path,
    );
    await _box.put(id, e.toJson());
    return e;
  }

  Future<HistoryEntry> addCollage({
    required List<Uint8List> sources,
    required Uint8List result,
    required Map<String, dynamic> spec,
    required String title,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await dir.create(recursive: true);
    final paths = <String>[];
    for (var i = 0; i < sources.length; i++) {
      final f = File(p.join(dir.path, '${id}_s$i.jpg'));
      await f.writeAsBytes(sources[i]);
      paths.add(f.path);
    }
    final r = File(p.join(dir.path, '${id}_r.png'));
    await r.writeAsBytes(result);
    final e = HistoryEntry(
      id: id,
      createdAt: DateTime.now(),
      prompt: title,
      auto: false,
      originalPath: paths.first,
      resultPath: r.path,
      sourcePaths: paths,
      spec: spec,
    );
    await _box.put(id, e.toJson());
    return e;
  }

  Future<void> rename(HistoryEntry e, String name) =>
      _box.put(e.id, e.withName(name.trim()).toJson());

  Future<void> delete(HistoryEntry e) async {
    await _box.delete(e.id);
    for (final path in {e.originalPath, e.resultPath, ...e.sourcePaths}) {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
  }
}
