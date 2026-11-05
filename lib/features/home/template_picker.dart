import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'templates.dart';

/// Category tabs + a grid of one-tap looks. [onPick] receives the prompt.
class TemplatePicker extends StatefulWidget {
  const TemplatePicker({
    super.key,
    required this.isZh,
    required this.enabled,
    required this.onPick,
  });

  final bool isZh;
  final bool enabled;
  final ValueChanged<String> onPick;

  @override
  State<TemplatePicker> createState() => _TemplatePickerState();
}

class _TemplatePickerState extends State<TemplatePicker> {
  int _cat = 0;
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final cats = kTemplateCategories;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cats.length,
            separatorBuilder: (_, _) => const SizedBox(width: 20),
            itemBuilder: (_, i) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _cat = i),
              child: Center(
                child: Text(
                  cats[i].name(widget.isZh),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: i == _cat ? FontWeight.w700 : FontWeight.w400,
                    color: i == _cat
                        ? CupertinoTheme.of(context).primaryColor
                        : secondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final t in cats[_cat].items)
              _Card(
                template: t,
                isZh: widget.isZh,
                selected: _picked == t.zh,
                onTap: widget.enabled
                    ? () {
                        HapticFeedback.selectionClick();
                        setState(() => _picked = t.zh);
                        widget.onPick(t.prompt(widget.isZh));
                      }
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.template,
    required this.isZh,
    required this.selected,
    required this.onTap,
  });

  final Template template;
  final bool isZh, selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final blue = CupertinoTheme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
            context,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? blue : const Color(0x00000000),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(template.icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(
              template.name(isZh),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
