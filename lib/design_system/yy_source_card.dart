import 'package:flutter/widgets.dart';

import 'src/yy_control_action.dart';
import 'yy_icon.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

/// Visual status tone only; source lifecycle and retry belong to feature code.
enum YYSourceStatusTone { positive, warning, error, neutral }

/// A controlled source summary action matching the final composed reference.
class YYSourceCard extends StatelessWidget {
  const YYSourceCard({
    super.key,
    required this.name,
    required this.meta,
    required this.glyph,
    required this.statusLabel,
    required this.statusTone,
    required this.onPressed,
    this.selected = false,
    this.loading = false,
    this.focusNode,
  }) : assert(name != ''),
       assert(meta != ''),
       assert(statusLabel != '');

  final String name;
  final String meta;
  final YYGlyph glyph;
  final String statusLabel;
  final YYSourceStatusTone statusTone;
  final VoidCallback? onPressed;
  final bool selected;
  final bool loading;
  final FocusNode? focusNode;

  Color _statusColor(YYPalette colors) => switch (statusTone) {
    YYSourceStatusTone.positive => YYPalette.success,
    YYSourceStatusTone.warning => YYPalette.warning,
    YYSourceStatusTone.error => YYPalette.error,
    YYSourceStatusTone.neutral => colors.tertiary,
  };

  @override
  Widget build(BuildContext context) => YYControlAction(
    label: '$name，$meta，$statusLabel',
    onActivate: onPressed,
    selected: selected,
    inMutuallyExclusiveGroup: false,
    loading: loading,
    focusNode: focusNode,
    builder: (context, interaction) {
      final theme = YYTheme.of(context);
      final colors = theme.colors;
      final selectedSurface = Color.alphaBlend(
        theme.accent.soft,
        colors.subtle,
      );
      final surface = selected
          ? selectedSurface
          : interaction.pressed
          ? colors.pressed
          : interaction.hovered
          ? colors.pressed
          : colors.subtle;
      final borderColor = interaction.focused
          ? colors.text
          : selected
          ? theme.accent.readableOn(surface)
          : interaction.hovered
          ? colors.strongBorder
          : const Color(0x00000000);
      final statusColor = _statusColor(colors);
      return AnimatedScale(
        duration: theme.motion(YYMotion.press),
        curve: YYMotion.standard,
        scale: interaction.pressed ? .995 : 1,
        child: AnimatedContainer(
          key: const ValueKey('yy-source-card-surface'),
          duration: theme.motion(YYMotion.hover),
          curve: YYMotion.standard,
          constraints: const BoxConstraints(
            minHeight: YYCollectionCardMetrics.sourceMinHeight,
          ),
          padding: const EdgeInsets.all(YYCollectionCardMetrics.sourcePadding),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(YYRadius.sourceCard),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                key: const ValueKey('yy-source-card-icon'),
                duration: theme.motion(YYMotion.hover),
                width: YYCollectionCardMetrics.sourceIcon,
                height: YYCollectionCardMetrics.sourceIcon,
                decoration: BoxDecoration(
                  color: colors.elevated,
                  borderRadius: BorderRadius.circular(YYRadius.sourceIcon),
                  border: Border.all(color: colors.border),
                ),
                child: Center(
                  child: YYIcon(
                    glyph: glyph,
                    size: 20,
                    color: theme.accent.readableOn(colors.elevated),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      loading ? '正在加载来源' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: YYTypography.sourceName.copyWith(
                        color: selected
                            ? theme.accent.readableOn(surface)
                            : colors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loading ? '请稍候' : meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: YYTypography.sourceMeta.copyWith(
                        color: colors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 92),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      key: const ValueKey('yy-source-status-dot'),
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(
                        dimension: YYCollectionCardMetrics.sourceStatusDot,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: YYTypography.sourceState.copyWith(
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
