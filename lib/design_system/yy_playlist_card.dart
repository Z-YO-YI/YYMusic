import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'src/yy_control_action.dart';
import 'yy_icon.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

enum YYPlaylistCardVariant { collection, create }

/// A controlled playlist action; it never reads or mutates playlist data.
class YYPlaylistCard extends StatelessWidget {
  const YYPlaylistCard({
    super.key,
    required this.title,
    required this.meta,
    required this.glyph,
    required this.onPressed,
    this.variant = YYPlaylistCardVariant.collection,
    this.selected = false,
    this.loading = false,
    this.focusNode,
  }) : assert(title != ''),
       assert(meta != '');

  final String title;
  final String meta;
  final YYGlyph glyph;
  final VoidCallback? onPressed;
  final YYPlaylistCardVariant variant;
  final bool selected;
  final bool loading;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => YYControlAction(
    label: '$title，$meta',
    onActivate: onPressed,
    selected: selected,
    inMutuallyExclusiveGroup: false,
    loading: loading,
    focusNode: focusNode,
    builder: (context, interaction) {
      final theme = YYTheme.of(context);
      final colors = theme.colors;
      final phone = MediaQuery.sizeOf(context).width < 600;
      final create = variant == YYPlaylistCardVariant.create;
      final selectedSurface = Color.alphaBlend(
        theme.accent.soft,
        colors.elevated,
      );
      final surface = selected
          ? selectedSurface
          : interaction.pressed
          ? colors.pressed
          : interaction.hovered
          ? colors.subtle
          : create
          ? const Color(0x00000000)
          : colors.elevated;
      final borderColor = interaction.focused
          ? colors.text
          : selected
          ? theme.accent.readableOn(surface)
          : interaction.hovered
          ? colors.strongBorder
          : colors.border;
      final iconDimension = phone
          ? YYCollectionCardMetrics.phonePlaylistIcon
          : YYCollectionCardMetrics.playlistIcon;
      final iconSurface = Color.alphaBlend(theme.accent.soft, colors.elevated);
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 180.0;
          return AnimatedSlide(
            duration: theme.motion(YYMotion.hover),
            curve: YYMotion.standard,
            offset: Offset(0, interaction.hovered ? -2 / width : 0),
            child: AnimatedScale(
              duration: theme.motion(YYMotion.press),
              curve: YYMotion.standard,
              scale: interaction.pressed ? .98 : 1,
              child: CustomPaint(
                key: const ValueKey('yy-playlist-card-border'),
                foregroundPainter: create
                    ? _DashedRoundedBorderPainter(
                        color: borderColor,
                        radius: YYRadius.playlistCard,
                      )
                    : null,
                child: AnimatedContainer(
                  key: const ValueKey('yy-playlist-card-surface'),
                  duration: theme.motion(YYMotion.hover),
                  curve: YYMotion.standard,
                  width: width,
                  padding: EdgeInsets.all(
                    phone
                        ? YYCollectionCardMetrics.phonePlaylistPadding
                        : YYCollectionCardMetrics.playlistPadding,
                  ),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(YYRadius.playlistCard),
                    border: create
                        ? null
                        : Border.all(
                            color: borderColor,
                            width: interaction.focused || selected ? 1.5 : 1,
                          ),
                    boxShadow: create
                        ? null
                        : const [
                            BoxShadow(
                              color: Color(0x0A0F1214),
                              offset: Offset(0, 6),
                              blurRadius: 18,
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        key: const ValueKey('yy-playlist-card-icon'),
                        duration: theme.motion(YYMotion.hover),
                        width: iconDimension,
                        height: iconDimension,
                        decoration: BoxDecoration(
                          color: iconSurface,
                          borderRadius: BorderRadius.circular(
                            YYRadius.playlistIcon,
                          ),
                          border: Border.all(
                            color: theme.accent.color.withValues(alpha: .16),
                          ),
                        ),
                        child: Center(
                          child: YYIcon(
                            glyph: glyph,
                            size: 24,
                            color: theme.accent.readableOn(iconSurface),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: YYCollectionCardMetrics.playlistTitleGap,
                      ),
                      Text(
                        loading ? '正在加载歌单' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: YYTypography.playlistTitle.copyWith(
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
                        style: YYTypography.playlistMeta.copyWith(
                          color: colors.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 1.0;
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final metric in path.computeMetrics()) {
      for (var offset = 0.0; offset < metric.length; offset += 9) {
        canvas.drawPath(
          metric.extractPath(offset, math.min(offset + 5, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
