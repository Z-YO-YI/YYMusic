import 'package:flutter/widgets.dart';

import 'src/yy_control_action.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

/// Search/history pill: base HTML chip geometry, native focus and semantics.
class YYSearchChip extends StatelessWidget {
  const YYSearchChip({
    super.key,
    required this.label,
    required this.onPressed,
    this.selected,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool? selected;
  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context);
    return YYControlAction(
      label: label,
      selected: selected,
      onActivate: onPressed,
      builder: (context, state) => Container(
        constraints: const BoxConstraints(minHeight: 34, maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected == true
              ? theme.colors.text
              : state.pressed || state.hovered
              ? theme.colors.subtle
              : theme.colors.elevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: state.focused ? theme.colors.text : theme.colors.border,
            width: state.focused ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: YYTypography.text(
            size: 11,
            weight: 620,
            color: selected == true
                ? theme.colors.base
                : theme.colors.secondary,
          ),
        ),
      ),
    );
  }
}
