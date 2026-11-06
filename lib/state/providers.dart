import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/debug_log.dart';
import '../core/image/image_saver.dart';
import '../core/image/preprocess.dart';
import '../core/models.dart';
import '../core/network/api_client.dart';
import '../core/network/api_error.dart';
import '../core/network/discovery.dart';
import '../core/network/image_edit_provider.dart';
import '../core/network/photo_analyzer.dart';
import '../core/network/provider_factory.dart';
import '../core/permissions/permission_service.dart';
import '../core/storage/history_repo.dart';
import '../core/storage/secure_store.dart';
import '../core/storage/settings_repo.dart';

// Overridden in main() with initialized instances.
final settingsRepoProvider = Provider<SettingsRepo>(
  (_) => throw UnimplementedError(),
);
final historyRepoProvider = Provider<HistoryRepo>(
  (_) => throw UnimplementedError(),
);

/// "1.1.0 (2)" from the installed package; empty if it cannot be read.
final appVersionProvider = FutureProvider<String>((_) async {
  try {
    final i = await PackageInfo.fromPlatform();
    return '${i.version} (${i.buildNumber})';
  } catch (_) {
    return '';
  }
});

/// Narrows History by creation kind and time. null = no limit.
class HistoryFilter {
  const HistoryFilter({this.kind, this.from, this.to});

  /// null = all, false = recolor only, true = collage only.
  final bool? kind;
  final DateTime? from;

  /// Inclusive end *day*.
  final DateTime? to;

  bool get isEmpty => kind == null && from == null && to == null;

  bool matches(HistoryEntry e) {
    if (kind != null && e.isCollage != kind) return false;
    if (from != null && e.createdAt.isBefore(from!)) return false;
    if (to != null) {
      final end = DateTime(to!.year, to!.month, to!.day + 1);
      if (!e.createdAt.isBefore(end)) return false;
    }
    return true;
  }
}

final historyFilterProvider = StateProvider<HistoryFilter>(
  (_) => const HistoryFilter(),
);

final secureStoreProvider = Provider<SecureStore>((_) => SecureStore());
final permissionServiceProvider = Provider((_) => const PermissionService());
final imageSaverProvider = Provider((_) => const ImageSaver());

/// Seam for tests: builds the network provider from settings + key.
typedef ProviderFactory =
    ImageEditProvider Function(AppSettings, String apiKey);
final providerFactoryProvider = Provider<ProviderFactory>(
  (_) => createProvider,
);

typedef EndpointDetector =
    Future<EndpointStyle?> Function(AppSettings, String apiKey);
final endpointDetectorProvider = Provider<EndpointDetector>(
  (_) =>
      (s, k) => detectEndpointStyle(createDio(s, k), s.model),
);

/// Seam for tests: asks the vision model about a photo (Smart mode).
typedef PhotoAnalyzer =
    Future<String> Function(
      AppSettings,
      String apiKey,
      EditRequest,
      CancelToken,
    );
final photoAnalyzerProvider = Provider<PhotoAnalyzer>(
  (_) =>
      (s, k, req, t) => describePhoto(createDio(s, k), s.visionModel, req, t),
);

typedef ModelLister = Future<List<String>> Function(AppSettings, String apiKey);
final modelListerProvider = Provider<ModelLister>(
  (_) =>
      (s, k) => fetchModelIds(createDio(s, k)),
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final s = ref.read(settingsRepoProvider).load();
    debugLog.enabled = s.debug;
    return s;
  }

  Future<void> update(AppSettings s) async {
    debugLog.enabled = s.debug;
    state = s;
    await ref.read(settingsRepoProvider).save(s);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class HistoryNotifier extends Notifier<List<HistoryEntry>> {
  @override
  List<HistoryEntry> build() => ref.read(historyRepoProvider).all();

  Future<void> delete(HistoryEntry e) async {
    await ref.read(historyRepoProvider).delete(e);
    state = ref.read(historyRepoProvider).all();
  }

  Future<void> rename(HistoryEntry e, String name) async {
    await ref.read(historyRepoProvider).rename(e, name);
    state = ref.read(historyRepoProvider).all();
  }

  void refresh() => state = ref.read(historyRepoProvider).all();
}

final historyProvider = NotifierProvider<HistoryNotifier, List<HistoryEntry>>(
  HistoryNotifier.new,
);

enum EditStatus { idle, preprocessing, analyzing, generating, done, failed }

class EditState {
  const EditState({
    this.status = EditStatus.idle,
    this.source,
    this.auto = true,
    this.prompt = '',
    this.result,
    this.error,
    this.imageError = false,
  });

  final EditStatus status;
  final PreprocessedImage? source;
  final bool auto;
  final String prompt;
  final Uint8List? result;
  final ApiError? error;
  final bool imageError;

  bool get busy => status == EditStatus.preprocessing || working;

  /// Smart analysis or image generation is in flight.
  bool get working =>
      status == EditStatus.analyzing || status == EditStatus.generating;

  EditState copyWith({
    EditStatus? status,
    PreprocessedImage? source,
    bool? auto,
    String? prompt,
    Uint8List? result,
    ApiError? error,
    bool imageError = false,
    bool clearResult = false,
    bool clearError = false,
  }) => EditState(
    status: status ?? this.status,
    source: source ?? this.source,
    auto: auto ?? this.auto,
    prompt: prompt ?? this.prompt,
    result: clearResult ? null : (result ?? this.result),
    error: clearError ? null : (error ?? this.error),
    imageError: imageError,
  );
}

class EditController extends Notifier<EditState> {
  CancelToken? _token;

  @override
  EditState build() => const EditState();

  void setAuto(bool auto) => state = state.copyWith(auto: auto);
  void setPrompt(String p) => state = state.copyWith(prompt: p);

  Future<void> setImage(Uint8List raw) async {
    state = state.copyWith(
      status: EditStatus.preprocessing,
      clearError: true,
      clearResult: true,
    );
    try {
      final src = await preprocessImage(raw);
      state = state.copyWith(status: EditStatus.idle, source: src);
    } on FormatException {
      state = state.copyWith(status: EditStatus.idle, imageError: true);
    }
  }

  /// Starts a new edit from an existing image (e.g. a history result).
  Future<void> continueFrom(Uint8List raw, {String prompt = ''}) async {
    await setImage(raw);
    if (state.source == null) return;
    state = state.copyWith(auto: false, prompt: prompt);
  }

  /// [effectivePrompt] is the localized Smart fallback prompt or the user's
  /// text. With [analysis] and a vision model configured, that model first
  /// reads the photo and answers [analysis].ask; its answer plus
  /// [analysis].keep replaces [effectivePrompt]. If the analysis fails,
  /// [effectivePrompt] is used instead.
  Future<void> generate(
    String effectivePrompt, {
    ({String ask, String keep})? analysis,
  }) async {
    final src = state.source;
    if (src == null || state.busy) return;
    var settings = ref.read(settingsProvider);
    final analyze = analysis != null && settings.visionModel.isNotEmpty;
    state = state.copyWith(
      status: analyze ? EditStatus.analyzing : EditStatus.generating,
      clearError: true,
      clearResult: true,
    );
    final token = _token = CancelToken();
    try {
      final key = await ref.read(secureStoreProvider).readApiKey();
      var prompt = effectivePrompt;
      if (analyze) {
        try {
          final brief = await ref.read(photoAnalyzerProvider)(
            settings,
            key,
            EditRequest(
              imageBytes: src.bytes,
              mimeType: src.mimeType,
              prompt: analysis.ask,
            ),
            token,
          );
          prompt = '$brief\n${analysis.keep}';
          debugLog.add('analysis: model=${settings.visionModel}\n$brief');
        } on ApiError catch (e) {
          if (e.type == ApiErrorType.cancelled) rethrow;
          debugLog.add('analysis failed, using built-in smart prompt: $e');
        }
        if (token.isCancelled) throw const ApiError(ApiErrorType.cancelled);
        state = state.copyWith(status: EditStatus.generating);
      }
      if (settings.endpointStyle == null) {
        final style = await ref.read(endpointDetectorProvider)(settings, key);
        if (token.isCancelled) throw const ApiError(ApiErrorType.cancelled);
        if (style == null) {
          throw ApiError(
            ApiErrorType.badResponse,
            message:
                'No /images/edits, /images/generations or /chat/completions at ${settings.baseUrl}',
          );
        }
        await ref
            .read(settingsProvider.notifier)
            .update(settings.copyWith(endpointStyle: style));
        settings = ref.read(settingsProvider);
      }
      debugLog.add(
        'generate: model=${settings.model} interface=${settings.endpointStyle?.name} image=${src.bytes.length} bytes ${src.width}x${src.height}',
      );
      final provider = ref.read(providerFactoryProvider)(settings, key);
      final res = await provider.edit(
        EditRequest(
          imageBytes: src.bytes,
          mimeType: src.mimeType,
          prompt: prompt,
        ),
        token,
      );
      state = state.copyWith(status: EditStatus.done, result: res.bytes);
      await ref
          .read(historyRepoProvider)
          .add(
            original: src.bytes,
            result: res.bytes,
            prompt: state.auto ? '' : state.prompt,
            auto: state.auto,
          );
      ref.read(historyProvider.notifier).refresh();
    } on ApiError catch (e) {
      debugLog.add('generate failed: $e');
      state = e.type == ApiErrorType.cancelled
          ? state.copyWith(status: EditStatus.idle)
          : state.copyWith(status: EditStatus.failed, error: e);
    } catch (e) {
      debugLog.add('generate error: $e');
      state = state.copyWith(
        status: EditStatus.failed,
        error: ApiError(ApiErrorType.badResponse, message: e.toString()),
      );
    }
  }

  void cancel() => _token?.cancel();

  /// Leave the result view but keep source, mode and prompt for a tweak.
  void backToEdit() =>
      state = state.copyWith(status: EditStatus.idle, clearResult: true);

  void ackError() =>
      state = state.copyWith(status: EditStatus.idle, clearError: true);
}

final editProvider = NotifierProvider<EditController, EditState>(
  EditController.new,
);
