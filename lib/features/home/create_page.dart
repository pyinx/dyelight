import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/permissions/permission_service.dart';
import '../../l10n/app_localizations.dart';
import '../../state/collage_providers.dart';
import '../../state/providers.dart';
import '../../ui/dialogs.dart';
import '../collage/collage_view.dart';
import '../result/result_page.dart';
import 'generating_overlay.dart';
import 'home_page.dart';
import 'workspace_back.dart';
import 'template_picker.dart';

class CreatePage extends ConsumerWidget {
  const CreatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(createModeProvider)) {
        null => const HomePage(),
        CreateMode.recolor => const RecolorView(),
        CreateMode.collage => const CollageView(),
      };
}

class RecolorView extends ConsumerStatefulWidget {
  const RecolorView({super.key});

  @override
  ConsumerState<RecolorView> createState() => _RecolorViewState();
}

class _RecolorViewState extends ConsumerState<RecolorView> {
  final _picker = ImagePicker();
  final _speech = SpeechToText();
  late final TextEditingController _promptCtrl;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _promptCtrl = TextEditingController(text: ref.read(editProvider).prompt);
  }

  @override
  void dispose() {
    _speech.cancel();
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _chooseSource() async {
    final l = AppLocalizations.of(context);
    final src = await showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l.chooseSource),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: Text(l.fromGallery),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: Text(l.takePhoto),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
      ),
    );
    if (src == null || !mounted) return;
    await _pick(src);
  }

  Future<void> _pick(ImageSource src) async {
    final l = AppLocalizations.of(context);
    final perms = ref.read(permissionServiceProvider);
    if (src == ImageSource.camera) {
      final r = await perms.request(Permission.camera);
      if (!mounted) return;
      if (r != PermissionOutcome.granted) {
        if (r == PermissionOutcome.permanentlyDenied) {
          await showPermissionDialog(
            context,
            l.permCameraBody,
            perms.openSettings,
          );
        }
        return;
      }
    }
    try {
      final file = await _picker.pickImage(source: src);
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      await ref.read(editProvider.notifier).setImage(bytes);
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (e.code == 'camera_access_denied' || e.code == 'photo_access_denied') {
        await showPermissionDialog(
          context,
          l.permCameraBody,
          perms.openSettings,
        );
      }
    }
  }

  Future<void> _toggleVoice() async {
    final l = AppLocalizations.of(context);
    final perms = ref.read(permissionServiceProvider);
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final r = await perms.request(Permission.microphone);
    if (!mounted) return;
    if (r != PermissionOutcome.granted) {
      if (r == PermissionOutcome.permanentlyDenied) {
        await showPermissionDialog(context, l.permMicBody, perms.openSettings);
      }
      return;
    }
    final ok = await _speech.initialize(
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && mounted) {
          setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    if (!ok) {
      showInfoDialog(context, l.voiceUnavailable);
      return;
    }
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    setState(() => _listening = true);
    HapticFeedback.selectionClick();
    await _speech.listen(
      listenOptions: SpeechListenOptions(localeId: zh ? 'zh_CN' : 'en_US'),
      onResult: (res) {
        _promptCtrl.text = res.recognizedWords;
        _promptCtrl.selection = TextSelection.collapsed(
          offset: _promptCtrl.text.length,
        );
        ref.read(editProvider.notifier).setPrompt(res.recognizedWords);
      },
    );
  }

  void _generate() {
    final l = AppLocalizations.of(context);
    final s = ref.read(editProvider);
    final prompt = s.auto ? l.autoPrompt : s.prompt.trim();
    if (prompt.isEmpty) {
      showInfoDialog(context, l.emptyPromptError);
      return;
    }
    HapticFeedback.mediumImpact();
    ref
        .read(editProvider.notifier)
        .generate(
          prompt,
          analysis: s.auto
              ? (ask: l.smartAnalysisPrompt, keep: l.smartKeepPrompt)
              : null,
        );
  }

  void _setPrompt(String prompt) {
    _promptCtrl.text = prompt;
    ref.read(editProvider.notifier).setPrompt(prompt);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(editProvider);
    final ctrl = ref.read(editProvider.notifier);

    ref.listen(editProvider.select((e) => e.status), (prev, next) {
      if (next == EditStatus.done && prev == EditStatus.generating) {
        final st = ref.read(editProvider);
        Navigator.of(context, rootNavigator: true)
            .push(
              CupertinoPageRoute<void>(
                builder: (_) => ResultPage(
                  original: st.source!.bytes,
                  result: st.result!,
                  onTweak: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                ),
              ),
            )
            .then((_) => ctrl.backToEdit());
      } else if (next == EditStatus.failed) {
        final err = ref.read(editProvider).error!;
        ctrl.ackError();
        showErrorDialog(context, err, onRetry: _generate);
      }
    });
    ref.listen(editProvider.select((e) => e.imageError), (_, bad) {
      if (bad) showInfoDialog(context, l.errImageTitle);
    });

    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final generating = s.working;

    return CupertinoPageScaffold(
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: Text(l.modeRecolor),
                  automaticallyImplyLeading: false,
                  leading: WorkspaceBack(enabled: !generating),
                ),
                SliverSafeArea(
                  top: false,
                  sliver: SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.list(
                      children: [
                        if (s.source == null)
                          _EmptyState(
                            title: l.emptyTitle,
                            hint: l.emptyHint,
                            button: l.pickPhoto,
                            busy: s.status == EditStatus.preprocessing,
                            onPressed: _chooseSource,
                          )
                        else ...[
                          _PhotoCard(
                            bytes: s.source!.bytes,
                            generating: generating,
                            analyzing: s.status == EditStatus.analyzing,
                            onCancel: ctrl.cancel,
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            onPressed: generating ? null : _chooseSource,
                            child: Text(l.replacePhoto),
                          ),
                          const SizedBox(height: 4),
                          CupertinoSlidingSegmentedControl<bool>(
                            groupValue: s.auto,
                            children: {
                              true: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text(l.modeAuto),
                              ),
                              false: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text(l.modeCustom),
                              ),
                            },
                            onValueChanged: (v) {
                              if (v == null || generating) return;
                              HapticFeedback.selectionClick();
                              ctrl.setAuto(v);
                            },
                          ),
                          const SizedBox(height: 16),
                          if (s.auto)
                            Text(
                              l.autoModeHint,
                              style: TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            )
                          else ...[
                            CupertinoTextField(
                              controller: _promptCtrl,
                              enabled: !generating,
                              minLines: 2,
                              maxLines: 5,
                              placeholder: _listening
                                  ? l.listening
                                  : l.promptPlaceholder,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: CupertinoColors
                                    .secondarySystemGroupedBackground
                                    .resolveFrom(context),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              suffix: CupertinoButton(
                                padding: const EdgeInsets.only(right: 8),
                                minimumSize: const Size(44, 44),
                                onPressed: generating ? null : _toggleVoice,
                                child: Icon(
                                  _listening
                                      ? CupertinoIcons.mic_fill
                                      : CupertinoIcons.mic,
                                  color: _listening
                                      ? CupertinoColors.systemRed
                                      : null,
                                ),
                              ),
                              onChanged: ctrl.setPrompt,
                            ),
                            const SizedBox(height: 12),
                            TemplatePicker(
                              isZh: isZh,
                              enabled: !generating,
                              onPick: _setPrompt,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (s.source != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(14),
                    onPressed: generating ? null : _generate,
                    child: Text(l.start),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
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
      padding: const EdgeInsets.only(top: 72),
      child: Column(
        children: [
          Icon(CupertinoIcons.photo_on_rectangle, size: 72, color: secondary),
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

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.bytes,
    required this.generating,
    required this.analyzing,
    required this.onCancel,
  });

  final Uint8List bytes;
  final bool generating, analyzing;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final w = (MediaQuery.sizeOf(context).width * dpr).round();
    return ClipRSuperellipse(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: Image.memory(
              bytes,
              width: double.infinity,
              fit: BoxFit.cover,
              cacheWidth: w,
            ),
          ),
          if (generating)
            Positioned.fill(
              child: GeneratingOverlay(
                analyzing: analyzing,
                onCancel: onCancel,
              ),
            ),
        ],
      ),
    );
  }
}
