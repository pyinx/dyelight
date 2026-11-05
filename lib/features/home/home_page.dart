import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../state/collage_providers.dart';
import 'templates.dart';

/// Create tab landing page: what the app does, and the way into each tool.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _open(WidgetRef ref, CreateMode mode) {
    HapticFeedback.selectionClick();
    ref.read(createModeProvider.notifier).state = mode;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final templateCount = kTemplateCategories.fold<int>(
      0,
      (n, c) => n + c.items.length,
    );
    final features = [
      (CupertinoIcons.sparkles, l.featByokTitle, l.featByokDesc),
      (CupertinoIcons.lock_shield, l.featPrivacyTitle, l.featPrivacyDesc),
      (CupertinoIcons.device_phone_portrait, l.featLocalTitle, l.featLocalDesc),
      (CupertinoIcons.clock, l.featHistoryTitle, l.featHistoryDesc),
    ];
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l.appTitle),
            automaticallyImplyLeading: false,
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.list(
                children: [
                  _Hero(tagline: l.homeTagline, intro: l.homeIntro),
                  const SizedBox(height: 16),
                  _EntryCard(
                    icon: CupertinoIcons.wand_stars,
                    color: const Color(0xFFFF9F0A),
                    title: l.homeRecolorTitle,
                    desc: l.homeRecolorDesc(templateCount),
                    cta: l.homeRecolorCta,
                    onTap: () => _open(ref, CreateMode.recolor),
                  ),
                  const SizedBox(height: 12),
                  _EntryCard(
                    icon: CupertinoIcons.square_grid_2x2,
                    color: const Color(0xFF30B0C7),
                    title: l.homeCollageTitle,
                    desc: l.homeCollageDesc,
                    cta: l.homeCollageCta,
                    onTap: () => _open(ref, CreateMode.collage),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 28, bottom: 8),
                    child: Text(
                      l.homeFeaturesTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (final f in features) _Feature(f.$1, f.$2, f.$3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.tagline, required this.intro});
  final String tagline, intro;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF9F0A), Color(0xFFFF375F), Color(0xFF5E5CE6)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tagline,
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          intro,
          style: const TextStyle(
            color: Color(0xE6FFFFFF),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.cta,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title, desc, cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Semantics(
      button: true,
      label: '$title. $desc',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
              context,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: secondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          cta,
                          style: TextStyle(
                            color: CupertinoTheme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: CupertinoTheme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.title, this.desc);
  final IconData icon;
  final String title, desc;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: CupertinoTheme.of(context).primaryColor),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
