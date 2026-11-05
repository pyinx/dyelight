import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/providers_preset.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import 'debug_log_page.dart';
import 'model_picker_page.dart';

Map<String, String> parseHeaders(String text) {
  final out = <String, String>{};
  for (final line in text.split('\n')) {
    final i = line.indexOf(':');
    if (i <= 0) continue;
    final k = line.substring(0, i).trim();
    final v = line.substring(i + 1).trim();
    if (k.isNotEmpty) out[k] = v;
  }
  return out;
}

String formatHeaders(Map<String, String> h) =>
    h.entries.map((e) => '${e.key}: ${e.value}').join('\n');

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _base, _key, _timeout, _headers;
  String? _testText;
  bool _testOk = false;
  bool _testing = false;
  bool _advanced = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _base = TextEditingController(text: s.baseUrl);
    _key = TextEditingController();
    _timeout = TextEditingController(text: s.timeoutSeconds.toString());
    _headers = TextEditingController(text: formatHeaders(s.headers));
    ref.read(secureStoreProvider).readApiKey().then((k) {
      if (mounted) _key.text = k;
    });
  }

  @override
  void dispose() {
    for (final c in [_base, _key, _timeout, _headers]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save(AppSettings Function(AppSettings) f) =>
      ref.read(settingsProvider.notifier).update(f(ref.read(settingsProvider)));

  String _providerName(AppSettings s, AppLocalizations l) =>
      presetById(s.providerId)?.name ?? l.providerCustom;

  Future<void> _pickProvider() async {
    final l = AppLocalizations.of(context);
    final id = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l.provider),
        actions: [
          for (final p in kProviderPresets)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, p.id),
              child: Text(p.name),
            ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, kCustomProviderId),
            child: Text(l.providerCustom),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
      ),
    );
    if (id == null || id == ref.read(settingsProvider).providerId) return;
    final preset = presetById(id);
    setState(() => _testText = null);
    if (preset != null) _base.text = preset.baseUrl;
    // Base URL / model changed: the interface must be detected again.
    _save(
      (s) => s.copyWith(
        providerId: id,
        baseUrl: preset?.baseUrl ?? normalizeBaseUrl(_base.text),
        model: preset?.defaultModel ?? s.model,
        clearEndpoint: true,
      ),
    );
  }

  Future<void> _pickModel() async {
    final m = await Navigator.of(context).push<String>(
      CupertinoPageRoute(
        builder: (_) => ModelPickerPage(
          settings: ref.read(settingsProvider),
          apiKey: _key.text.trim(),
        ),
      ),
    );
    if (m == null || m == ref.read(settingsProvider).model) return;
    setState(() => _testText = null);
    _save((s) => s.copyWith(model: m, clearEndpoint: true));
  }

  String _path(EndpointStyle e, AppLocalizations l) => switch (e) {
    EndpointStyle.imagesEdits => l.endpointImagesEdits,
    EndpointStyle.imagesGenerations => l.endpointImagesGenerations,
    EndpointStyle.chatCompletions => l.endpointChat,
  };

  Future<void> _test() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _testing = true;
      _testText = null;
    });
    final s = ref.read(settingsProvider);
    final key = _key.text.trim();
    final report = await ref
        .read(providerFactoryProvider)(s, key)
        .testConnection();
    String text;
    var ok = false;
    if (!report.reachable) {
      text = l.testUnreachable;
    } else if (!report.authOk) {
      text = l.testAuthFailed;
    } else if (report.statusCode != null &&
        report.statusCode! >= 400 &&
        report.statusCode! != 404 &&
        report.statusCode! != 405) {
      text =
          '${l.testStatus(report.statusCode.toString())}${report.detail == null ? '' : ' · ${report.detail}'}';
    } else {
      ok = true;
      text = switch (report.modelListed) {
        true => '${l.testOk}\n${l.testModelListed(s.model)}',
        false => '${l.testOk}\n${l.testModelMissing(s.model)}',
        null => '${l.testOk}\n${l.testNoModelList}',
      };
      EndpointStyle? style;
      try {
        style = await ref.read(endpointDetectorProvider)(s, key);
      } on ApiError {
        style = null;
      }
      if (style != null) {
        text += '\n${l.interfaceDetected(_path(style, l))}';
        if (mounted) _save((c) => c.copyWith(endpointStyle: style));
      } else {
        ok = false;
        text += '\n${l.interfaceUndetected}';
      }
    }
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testText = text;
      _testOk = ok;
    });
  }

  Widget _label(String t) => SizedBox(
    width: 110,
    child: Text(t, style: const TextStyle(fontSize: 16)),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final custom = s.providerId == kCustomProviderId;

    CupertinoListTile row(String label, Widget field) => CupertinoListTile(
      title: Row(
        children: [
          _label(label),
          Expanded(child: field),
        ],
      ),
    );

    Widget field(
      TextEditingController c, {
      bool obscure = false,
      TextInputType? type,
      required ValueChanged<String> onChanged,
      String? placeholder,
    }) => CupertinoTextField.borderless(
      controller: c,
      obscureText: obscure,
      keyboardType: type,
      autocorrect: false,
      enableSuggestions: false,
      textAlign: TextAlign.end,
      placeholder: placeholder,
      padding: EdgeInsets.zero,
      onChanged: onChanged,
    );

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l.tabSettings),
            automaticallyImplyLeading: false,
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverList.list(
              children: [
                CupertinoListSection.insetGrouped(
                  header: Text(l.sectionServer),
                  children: [
                    CupertinoListTile(
                      title: Text(l.provider),
                      additionalInfo: Text(_providerName(s, l)),
                      trailing: const CupertinoListTileChevron(),
                      onTap: _pickProvider,
                    ),
                    if (custom)
                      row(
                        l.baseUrl,
                        field(
                          _base,
                          type: TextInputType.url,
                          placeholder: 'https://host/v1',
                          onChanged: (v) {
                            _save(
                              (c) => c.copyWith(
                                baseUrl: normalizeBaseUrl(v),
                                clearEndpoint: true,
                              ),
                            );
                          },
                        ),
                      ),
                    row(
                      l.apiKey,
                      field(
                        _key,
                        obscure: true,
                        placeholder: 'sk-…',
                        onChanged: (v) =>
                            ref.read(secureStoreProvider).writeApiKey(v.trim()),
                      ),
                    ),
                    CupertinoListTile(
                      title: Text(l.modelId),
                      additionalInfo: Text(s.model),
                      trailing: const CupertinoListTileChevron(),
                      onTap: _pickModel,
                    ),
                    CupertinoListTile(
                      title: Text(l.endpointStyle),
                      additionalInfo: Text(
                        s.endpointStyle == null
                            ? l.interfaceAuto
                            : _path(s.endpointStyle!, l),
                      ),
                    ),
                  ],
                ),
                CupertinoListSection.insetGrouped(
                  footer: _testText == null
                      ? null
                      : Text(
                          _testText!,
                          style: TextStyle(
                            fontSize: 14,
                            color: _testOk
                                ? CupertinoColors.systemGreen
                                : CupertinoColors.systemRed,
                          ),
                        ),
                  children: [
                    CupertinoListTile(
                      title: Center(
                        child: _testing
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CupertinoActivityIndicator(),
                                  const SizedBox(width: 8),
                                  Text(l.testing),
                                ],
                              )
                            : Text(
                                l.testConnection,
                                style: const TextStyle(
                                  color: CupertinoColors.activeBlue,
                                ),
                              ),
                      ),
                      onTap: _testing ? null : _test,
                    ),
                  ],
                ),
                CupertinoListSection.insetGrouped(
                  header: Text(l.language),
                  children: [
                    CupertinoListTile(
                      title: SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<String>(
                          groupValue: s.localeCode ?? 'system',
                          children: {
                            'system': Text(l.langSystem),
                            'zh': Text(l.langZh),
                            'en': Text(l.langEn),
                          },
                          onValueChanged: (v) {
                            if (v == null) return;
                            _save(
                              (s) => v == 'system'
                                  ? s.copyWith(clearLocale: true)
                                  : s.copyWith(localeCode: v),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                CupertinoListSection.insetGrouped(
                  header: Text(l.sectionAdvanced),
                  children: [
                    CupertinoListTile(
                      title: Text(l.sectionAdvanced),
                      trailing: Icon(
                        _advanced
                            ? CupertinoIcons.chevron_up
                            : CupertinoIcons.chevron_down,
                        size: 16,
                      ),
                      onTap: () => setState(() => _advanced = !_advanced),
                    ),
                    if (_advanced) ...[
                      row(
                        l.timeout,
                        field(
                          _timeout,
                          type: TextInputType.number,
                          onChanged: (v) {
                            final n = int.tryParse(v);
                            if (n != null && n > 0) {
                              _save((s) => s.copyWith(timeoutSeconds: n));
                            }
                          },
                        ),
                      ),
                      CupertinoListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.customHeaders),
                            const SizedBox(height: 6),
                            CupertinoTextField.borderless(
                              controller: _headers,
                              minLines: 2,
                              maxLines: 5,
                              autocorrect: false,
                              enableSuggestions: false,
                              padding: EdgeInsets.zero,
                              onChanged: (v) => _save(
                                (s) => s.copyWith(headers: parseHeaders(v)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoListTile(
                        title: Row(
                          children: [
                            _label(l.temperature),
                            Expanded(
                              child: CupertinoSlider(
                                value: s.temperature,
                                min: 0,
                                max: 2,
                                divisions: 20,
                                onChanged: (v) =>
                                    _save((s) => s.copyWith(temperature: v)),
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                s.temperature.toStringAsFixed(1),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                CupertinoListSection.insetGrouped(
                  header: Text(l.debugSection),
                  footer: Text(l.debugModeHint),
                  children: [
                    CupertinoListTile(
                      title: Text(l.debugMode),
                      trailing: CupertinoSwitch(
                        value: s.debug,
                        onChanged: (v) => _save((c) => c.copyWith(debug: v)),
                      ),
                    ),
                    if (s.debug)
                      CupertinoListTile(
                        title: Text(l.debugLogView),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () => Navigator.of(context).push(
                          CupertinoPageRoute<void>(
                            builder: (_) => const DebugLogPage(),
                          ),
                        ),
                      ),
                  ],
                ),
                CupertinoListSection.insetGrouped(
                  header: Text(l.aboutSection),
                  children: [
                    CupertinoListTile(
                      title: Text(l.appVersion),
                      additionalInfo: Text(
                        ref.watch(appVersionProvider).valueOrNull ?? '',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
