import 'package:flutter/widgets.dart';

import 'src/yy_control_action.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

/// A 30px audited color sample inside a platform-safe 44px action target.
class YYThemeSwatch extends StatelessWidget {
  const YYThemeSwatch({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onPressed,
    this.loading = false,
    this.focusNode,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onPressed;
  final bool loading;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: YYSpace.touchTarget,
    child: YYControlAction(
      label: label,
      onActivate: onPressed,
      selected: selected,
      loading: loading,
      focusNode: focusNode,
      builder: (context, interaction) {
        final theme = YYTheme.of(context);
        final colors = theme.colors;
        final scale = interaction.pressed
            ? .9
            : interaction.hovered
            ? 1.06
            : 1.0;
        return Center(
          child: AnimatedScale(
            duration: theme.motion(YYMotion.press),
            curve: YYMotion.standard,
            scale: scale,
            child: AnimatedContainer(
              key: ValueKey('theme-swatch-$label'),
              duration: theme.motion(YYMotion.hover),
              curve: YYMotion.standard,
              width: YYFeedbackMetrics.themeSwatchVisual,
              height: YYFeedbackMetrics.themeSwatchVisual,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: colors.elevated, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: interaction.focused ? colors.text : colors.border,
                    spreadRadius: interaction.focused ? 2 : 1,
                  ),
                ],
              ),
              child: selected
                  ? Center(
                      child: DecoratedBox(
                        key: const ValueKey('theme-swatch-selection'),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: YYAccent.foregroundFor(color),
                            width: 2,
                          ),
                        ),
                        child: const SizedBox.square(dimension: 12),
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    ),
  );
}
