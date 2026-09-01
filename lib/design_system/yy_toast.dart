import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'yy_icon.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

/// Controlled accessible toast. Queueing and display duration stay external.
class YYToast extends StatelessWidget {
  const YYToast({
    super.key,
    required this.message,
    required this.visible,
    this.glyph = YYGlyph.check,
  }) : assert(message != '');

  final String message;
  final bool visible;
  final YYGlyph glyph;

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context);
    final colors = theme.colors;
    final maxWidth = math.max(
      0.0,
      math.min(
        YYOverlayMetrics.toastMaxWidth,
        MediaQuery.sizeOf(context).width - 32,
      ),
    );
    return Semantics(
      container: true,
      liveRegion: visible,
      hidden: !visible,
      label: visible ? message : null,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedSlide(
            duration: theme.motion(const Duration(milliseconds: 220)),
            curve: YYMotion.enter,
            offset: visible ? Offset.zero : const Offset(0, .22),
            child: AnimatedOpacity(
              duration: theme.motion(const Duration(milliseconds: 180)),
              curve: YYMotion.standard,
              opacity: visible ? 1 : 0,
              child: ConstrainedBox(
                key: const ValueKey('yy-toast'),
                constraints: BoxConstraints(
                  minHeight: YYOverlayMetrics.toastMinHeight,
                  maxWidth: maxWidth,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.text,
                    borderRadius: BorderRadius.circular(YYRadius.toast),
                    boxShadow: YYShadows.floating(theme.brightness),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        YYIcon(glyph: glyph, size: 18, color: colors.elevated),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: YYTypography.text(
                              size: 11,
                              weight: 620,
                              color: colors.elevated,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
