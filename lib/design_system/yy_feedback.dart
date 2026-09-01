import 'package:flutter/widgets.dart';

import 'yy_button.dart';
import 'yy_icon.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

/// Compact empty state from the base reference. Feature code owns its meaning.
class YYEmptyState extends StatelessWidget {
  const YYEmptyState({
    super.key,
    required this.message,
    this.glyph,
    this.action,
  }) : assert(message != '');

  final String message;
  final YYGlyph? glyph;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: '空状态，$message',
      child: Padding(
        key: const ValueKey('yy-empty-state'),
        padding: const EdgeInsets.symmetric(
          horizontal: YYFeedbackMetrics.emptyHorizontalPadding,
          vertical: YYFeedbackMetrics.emptyVerticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph != null) ...[
              YYIcon(
                glyph: glyph!,
                size: YYFeedbackMetrics.emptyIconSize,
                color: theme.accent.readableOn(theme.colors.elevated),
              ),
              const SizedBox(height: 10),
            ],
            ExcludeSemantics(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: YYTypography.text(
                  size: 10,
                  weight: 500,
                  height: 1.6,
                  color: theme.colors.tertiary,
                ),
              ),
            ),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}

/// Error feedback adapted from the reference notice and error badge tokens.
class YYErrorBanner extends StatelessWidget {
  const YYErrorBanner({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionLoading = false,
  }) : assert(title != ''),
       assert(message != ''),
       assert(actionLabel != null || onAction == null);

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool actionLoading;

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context);
    final colors = theme.colors;
    final errorFill = YYPalette.error.withValues(alpha: .09);
    final errorBorder = YYPalette.error.withValues(alpha: .18);
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: YYIcon(glyph: YYGlyph.info, size: 20, color: YYPalette.error),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: YYTypography.text(
                    size: 11,
                    weight: 700,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: YYTypography.text(
                    size: 10,
                    weight: 500,
                    height: 1.55,
                    color: colors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: 10),
          YYButton(
            label: actionLabel!,
            onPressed: onAction,
            loading: actionLoading,
            style: YYButtonStyle.quiet,
          ),
        ],
      ],
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      liveRegion: true,
      label: '错误，$title。$message',
      child: DecoratedBox(
        key: const ValueKey('yy-error-banner'),
        decoration: BoxDecoration(
          color: errorFill,
          borderRadius: BorderRadius.circular(YYFeedbackMetrics.bannerRadius),
          border: Border.all(color: errorBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: content,
        ),
      ),
    );
  }
}

/// Solid-color loading placeholder; gradients and fabricated data are avoided.
class YYSkeleton extends StatelessWidget {
  const YYSkeleton({
    super.key,
    required this.height,
    this.width,
    this.radius = YYFeedbackMetrics.skeletonRadius,
    this.semanticLabel = '正在加载',
  }) : assert(height > 0),
       assert(width == null || width > 0),
       assert(radius >= 0),
       assert(semanticLabel != '');

  final double height;
  final double? width;
  final double radius;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          key: const ValueKey('yy-skeleton'),
          width: width ?? double.infinity,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.subtle,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: colors.border),
            ),
          ),
        ),
      ),
    );
  }
}
