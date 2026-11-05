import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/collage_providers.dart';

/// Leads from a Recolor/Collage workspace back to the Create home.
class WorkspaceBack extends ConsumerWidget {
  const WorkspaceBack({super.key, this.enabled = true});
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      CupertinoNavigationBarBackButton(
        onPressed: enabled
            ? () => ref.read(createModeProvider.notifier).state = null
            : () {},
      );
}
