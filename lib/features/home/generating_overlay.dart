import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

import '../../l10n/app_localizations.dart';

/// Pulsing, blurred overlay with friendly rotating copy and a Cancel button.
class GeneratingOverlay extends StatefulWidget {
  const GeneratingOverlay({super.key, required this.onCancel});
  final VoidCallback onCancel;

  @override
  State<GeneratingOverlay> createState() => _GeneratingOverlayState();
}

class _GeneratingOverlayState extends State<GeneratingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);
  Timer? _timer;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _i++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lines = [l.generating1, l.generating2, l.generating3];
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => ColoredBox(
          color: const Color(
            0xFF000000,
          ).withValues(alpha: 0.25 + 0.2 * _pulse.value),
          child: child,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(
              radius: 14,
              color: CupertinoColors.white,
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                lines[_i % lines.length],
                key: ValueKey(_i % lines.length),
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            CupertinoButton(
              onPressed: widget.onCancel,
              child: Text(
                l.cancelGeneration,
                style: const TextStyle(color: CupertinoColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
