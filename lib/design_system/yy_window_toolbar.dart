import 'package:flutter/widgets.dart';

import 'src/yy_control_action.dart';
import 'yy_icon.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';
import 'yy_tooltip.dart';

/// Controlled Windows app toolbar. OS calls belong to WindowsWindowGateway.
class YYWindowToolbar extends StatelessWidget {
  const YYWindowToolbar({
    super.key,
    this.title = 'YYMusic',
    this.centerLabel = '本地音乐与在线音乐，保持同一种节奏',
    this.showWindowControls = true,
    this.maximized = false,
    this.onMinimize,
    this.onToggleMaximize,
    this.onClose,
  });

  final String title;
  final String centerLabel;
  final bool showWindowControls;
  final bool maximized;
  final VoidCallback? onMinimize;
  final VoidCallback? onToggleMaximize;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    return SizedBox(
      key: const ValueKey('yy-window-toolbar'),
      height: YYWindowsMetrics.toolbarHeight,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: YYTheme.of(context).accent.color,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    title,
                    style: YYTypography.text(
                      size: 12,
                      weight: 650,
                      spacing: .2,
                      color: colors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            if (constraints.maxWidth >= 760)
              IgnorePointer(
                child: Text(
                  centerLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: YYTypography.text(
                    size: 12,
                    weight: 550,
                    color: colors.tertiary,
                  ),
                ),
              ),
            if (showWindowControls)
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _WindowControl(
                      glyph: YYGlyph.minimize,
                      label: '最小化',
                      onPressed: onMinimize,
                    ),
                    _WindowControl(
                      glyph: YYGlyph.maximize,
                      label: maximized ? '还原' : '最大化',
                      onPressed: onToggleMaximize,
                    ),
                    _WindowControl(
                      glyph: YYGlyph.close,
                      label: '关闭',
                      danger: true,
                      onPressed: onClose,
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

class _WindowControl extends StatelessWidget {
  const _WindowControl({
    required this.glyph,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final YYGlyph glyph;
  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) => YYTooltip(
    message: label,
    child: YYControlAction(
      label: label,
      onActivate: onPressed,
      builder: (context, interaction) {
        final theme = YYTheme.of(context);
        final colors = theme.colors;
        final active = interaction.hovered || interaction.pressed;
        final fill = danger && active
            ? YYPalette.error.withValues(alpha: .13)
            : interaction.pressed
            ? colors.pressed
            : interaction.hovered
            ? colors.subtle
            : const Color(0x00000000);
        final ink = danger && active ? YYPalette.error : colors.secondary;
        return AnimatedContainer(
          key: ValueKey('window-control-$label'),
          duration: theme.motion(YYMotion.hover),
          curve: YYMotion.standard,
          width: YYSpace.touchTarget,
          height: YYWindowsMetrics.toolbarHeight,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: interaction.focused
                  ? colors.text
                  : const Color(0x00000000),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: YYIcon(glyph: glyph, size: 16, color: ink),
        );
      },
    ),
  );
}
