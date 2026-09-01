import 'package:flutter/widgets.dart';

import 'src/yy_control_action.dart';
import 'yy_button.dart';
import 'yy_icon.dart';
import 'yy_navigation.dart';
import 'yy_profile_header.dart';
import 'yy_surface.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';
import 'yy_tooltip.dart';

/// Controlled Windows navigation; route and source truth stay outside.
class YYWindowsSidebar extends StatelessWidget {
  const YYWindowsSidebar({
    super.key,
    required this.compact,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.sourceLabel,
    required this.sourceDescription,
    this.sourceConnected = false,
    this.onManageSources,
    this.onAccountMore,
  }) : assert(destinations.length >= 2),
       assert(selectedIndex >= 0 && selectedIndex < destinations.length);

  final bool compact;
  final List<YYNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String sourceLabel;
  final String sourceDescription;
  final bool sourceConnected;
  final VoidCallback? onManageSources;
  final VoidCallback? onAccountMore;

  @override
  Widget build(BuildContext context) {
    final width = compact
        ? YYWindowsMetrics.sidebarCompactWidth
        : YYWindowsMetrics.sidebarExpandedWidth;
    return SizedBox(
      key: const ValueKey('yy-windows-sidebar'),
      width: width,
      child: YYGlassPanel(
        blurSigma: compact ? 34 : 40,
        padding: EdgeInsets.fromLTRB(
          compact ? 8 : 14,
          compact ? 12 : 18,
          compact ? 8 : 14,
          14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 54,
              child: Align(
                alignment: compact ? Alignment.topCenter : Alignment.centerLeft,
                child: YYProfileHeader(compact: compact),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var index = 0; index < destinations.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: _WindowsNavigationItem(
                          compact: compact,
                          destination: destinations[index],
                          selected: selectedIndex == index,
                          onPressed: () => onSelected(index),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (!compact) ...[
              _SourceStatus(
                label: sourceLabel,
                description: sourceDescription,
                connected: sourceConnected,
                onManage: onManageSources,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: YYTooltip(
                  message: '更多账户选项',
                  child: YYIconButton(
                    glyph: YYGlyph.more,
                    label: '更多账户选项',
                    style: YYButtonStyle.quiet,
                    onPressed: onAccountMore,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WindowsNavigationItem extends StatelessWidget {
  const _WindowsNavigationItem({
    required this.compact,
    required this.destination,
    required this.selected,
    required this.onPressed,
  });

  final bool compact;
  final YYNavigationDestination destination;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final action = YYControlAction(
      label: destination.label,
      selected: selected,
      onActivate: onPressed,
      builder: (context, interaction) {
        final theme = YYTheme.of(context);
        final colors = theme.colors;
        final selectedSurface = Color.alphaBlend(
          theme.accent.soft,
          colors.elevated,
        );
        final fill = selected
            ? selectedSurface
            : interaction.pressed
            ? colors.pressed
            : interaction.hovered
            ? colors.subtle
            : const Color(0x00000000);
        final ink = selected
            ? theme.accent.readableOn(selectedSurface)
            : interaction.hovered
            ? colors.text
            : colors.secondary;
        return AnimatedScale(
          duration: theme.motion(YYMotion.press),
          curve: YYMotion.standard,
          scale: interaction.pressed ? .98 : 1,
          child: AnimatedContainer(
            key: ValueKey('windows-nav-${destination.id}'),
            duration: theme.motion(YYMotion.hover),
            curve: YYMotion.standard,
            height: compact ? 52 : YYWindowsMetrics.navigationItemHeight,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(YYRadius.navigation),
              border: Border.all(
                color: interaction.focused
                    ? colors.text
                    : const Color(0x00000000),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 12),
                  child: Row(
                    mainAxisAlignment: compact
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      YYIcon(
                        glyph: destination.glyph,
                        size: YYNavigationMetrics.iconSize,
                        color: ink,
                      ),
                      if (!compact) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            destination.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: YYTypography.text(
                              size: 13,
                              weight: selected ? 680 : 620,
                              color: ink,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected)
                  const Positioned(
                    left: 0,
                    child: YYNavigationSelectionIndicator(),
                  ),
              ],
            ),
          ),
        );
      },
    );
    return compact
        ? YYTooltip(message: destination.label, child: action)
        : action;
  }
}

class _SourceStatus extends StatelessWidget {
  const _SourceStatus({
    required this.label,
    required this.description,
    required this.connected,
    required this.onManage,
  });

  final String label;
  final String description;
  final bool connected;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context);
    final colors = theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.accent.color.withValues(alpha: .075),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.accent.color.withValues(alpha: .13)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              container: true,
              label: '$label。$description',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: connected
                              ? YYPalette.success
                              : colors.tertiary,
                          boxShadow: connected
                              ? [
                                  BoxShadow(
                                    color: YYPalette.success.withValues(
                                      alpha: .12,
                                    ),
                                    spreadRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: YYTypography.text(size: 12, weight: 680),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: YYTypography.text(
                      size: 11,
                      height: 1.55,
                      color: colors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            YYButton(
              label: '管理音乐源',
              glyph: YYGlyph.plus,
              style: YYButtonStyle.quiet,
              onPressed: onManage,
            ),
          ],
        ),
      ),
    );
  }
}
