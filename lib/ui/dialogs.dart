import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../core/network/api_error.dart';
import '../l10n/app_localizations.dart';

Future<void> showErrorDialog(
  BuildContext context,
  ApiError e, {
  VoidCallback? onRetry,
}) {
  final l = AppLocalizations.of(context);
  final (title, body) = switch (e.type) {
    ApiErrorType.timeout => (l.errTimeoutTitle, l.errTimeoutBody),
    ApiErrorType.safety => (l.errSafetyTitle, l.errSafetyBody),
    ApiErrorType.auth => (l.errAuthTitle, l.errAuthBody),
    ApiErrorType.network => (l.errNetworkTitle, l.errNetworkBody),
    ApiErrorType.badResponse => (l.errBadTitle, l.errBadBody),
    ApiErrorType.cancelled => (l.errGenericTitle, ''),
  };
  final detail = [
    if (e.statusCode != null) l.testStatus(e.statusCode.toString()),
    if (e.message != null && e.message!.isNotEmpty) e.message!,
  ].join(' · ');
  HapticFeedback.heavyImpact();
  return showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(detail.isEmpty ? body : '$body\n\n$detail'),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
        if (onRetry != null)
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              onRetry();
            },
            child: Text(l.retry),
          ),
      ],
    ),
  );
}

Future<void> showInfoDialog(
  BuildContext context,
  String title, [
  String? body,
]) {
  final l = AppLocalizations.of(context);
  return showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.ok),
        ),
      ],
    ),
  );
}

/// Guides the user to system Settings after a permission was refused.
Future<void> showPermissionDialog(
  BuildContext context,
  String body,
  Future<bool> Function() openSettings,
) {
  final l = AppLocalizations.of(context);
  return showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(l.permTitle),
      content: Text(body),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(ctx);
            openSettings();
          },
          child: Text(l.openSettings),
        ),
      ],
    ),
  );
}

/// Lightweight, non-blocking confirmation (iOS-style pill).
void showToast(BuildContext context, String message) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      left: 24,
      right: 24,
      bottom: MediaQuery.paddingOf(ctx).bottom + 96,
      child: IgnorePointer(
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: CupertinoColors.black.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                message,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 15,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Timer(const Duration(milliseconds: 1800), entry.remove);
}

Future<bool> showDeleteConfirm(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final r = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(l.deleteConfirm),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.delete),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Returns the new name, or null if cancelled.
Future<String?> showRenameDialog(BuildContext context, String initial) {
  final l = AppLocalizations.of(context);
  final ctrl = TextEditingController(text: initial);
  return showCupertinoDialog<String>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(l.rename),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CupertinoTextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 40,
          placeholder: l.renameHint,
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx, ctrl.text),
          child: Text(l.save),
        ),
      ],
    ),
  ).whenComplete(ctrl.dispose);
}
