import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';

/// Fetches `/models` on open; the search box doubles as manual entry.
class ModelPickerPage extends ConsumerStatefulWidget {
  const ModelPickerPage({
    super.key,
    required this.settings,
    required this.apiKey,
  });
  final AppSettings settings;
  final String apiKey;

  @override
  ConsumerState<ModelPickerPage> createState() => _ModelPickerPageState();
}

class _ModelPickerPageState extends ConsumerState<ModelPickerPage> {
  final _query = TextEditingController();
  List<String>? _models;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _models = null;
      _failed = false;
    });
    try {
      final ids = await ref.read(modelListerProvider)(
        widget.settings,
        widget.apiKey,
      );
      if (mounted) setState(() => _models = ids);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final q = _query.text.trim();
    final all = _models ?? const <String>[];
    final shown = q.isEmpty
        ? all
        : all.where((m) => m.toLowerCase().contains(q.toLowerCase())).toList();
    final canUseTyped = q.isNotEmpty && !all.contains(q);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l.selectModel)),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: CupertinoSearchTextField(
                controller: _query,
                placeholder: l.searchModels,
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (canUseTyped)
                    CupertinoListTile(
                      title: Text(l.useModel(q)),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () => Navigator.pop(context, q),
                    ),
                  if (_models == null && !_failed)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const CupertinoActivityIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            l.fetchingModels,
                            style: TextStyle(color: secondary),
                          ),
                        ],
                      ),
                    )
                  else if (_failed)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            l.modelsFailed,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: secondary),
                          ),
                          CupertinoButton(
                            onPressed: _load,
                            child: Text(l.retry),
                          ),
                        ],
                      ),
                    )
                  else if (shown.isEmpty && !canUseTyped)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          l.noModelsFound,
                          style: TextStyle(color: secondary),
                        ),
                      ),
                    ),
                  for (final m in shown)
                    CupertinoListTile(
                      title: Text(
                        m,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: m == widget.settings.model
                          ? const Icon(
                              CupertinoIcons.checkmark_alt,
                              color: CupertinoColors.activeBlue,
                            )
                          : null,
                      onTap: () => Navigator.pop(context, m),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
