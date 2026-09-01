import 'package:flutter/widgets.dart';

import 'src/yy_control_action.dart';
import 'yy_artwork_placeholder.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

/// A controlled album action matching the final App.tsx card geometry.
///
/// This component owns no media or selection state. The caller supplies the
/// displayed labels, artwork fixture or real artwork replacement, and action.
class YYAlbumCard extends StatelessWidget {
  const YYAlbumCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.artwork,
    required this.onPressed,
    this.selected = false,
    this.loading = false,
    this.focusNode,
  });

  final String title;
  final String subtitle;
  final YYArtworkKind artwork;
  final VoidCallback? onPressed;
  final bool selected;
  final bool loading;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => YYControlAction(
    label: '$title，$subtitle',
    onActivate: onPressed,
    selected: selected,
    inMutuallyExclusiveGroup: false,
    loading: loading,
    focusNode: focusNode,
    builder: (context, interaction) {
      final theme = YYTheme.of(context);
      final colors = theme.colors;
      final duration = theme.motion(YYMotion.selected);
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 148.0;
          final artworkDimension = (width - 4).clamp(1.0, double.infinity);
          final artworkWidget = Stack(
            fit: StackFit.passthrough,
            children: [
              YYArtworkPlaceholder(
                kind: artwork,
                dimension: artworkDimension,
                semanticLabel: '$title 封面占位',
                hovered: interaction.hovered,
              ),
              if (selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          YYRadius.albumArtwork,
                        ),
                        border: Border.all(
                          color: theme.accent.readableOn(colors.elevated),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
          return AnimatedContainer(
            key: const ValueKey('yy-album-card-surface'),
            duration: theme.motion(YYMotion.press),
            curve: YYMotion.standard,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(YYRadius.albumArtwork + 2),
              border: Border.all(
                color: interaction.focused
                    ? colors.text
                    : const Color(0x00000000),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSlide(
                  duration: duration,
                  curve: YYMotion.standard,
                  offset: Offset(
                    0,
                    interaction.hovered ? -3 / artworkDimension : 0,
                  ),
                  child: AnimatedScale(
                    key: const ValueKey('yy-album-card-art-motion'),
                    duration: duration,
                    curve: YYMotion.standard,
                    scale: interaction.pressed ? .98 : 1,
                    child: Opacity(
                      opacity: loading ? .32 : 1,
                      child: artworkWidget,
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  loading ? '正在加载' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: YYTypography.albumTitle.copyWith(
                    color: selected
                        ? theme.accent.readableOn(colors.elevated)
                        : colors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  loading ? '请稍候' : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: YYTypography.albumMeta.copyWith(
                    color: colors.tertiary,
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
