import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'yy_theme.dart';
import 'yy_tokens.dart';

/// The ordinary opaque card surface; blur is opt-in via YYGlassSurface.
class YYSurface extends StatelessWidget {
  const YYSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(YYRadius.surface),
        border: Border.all(color: colors.border),
        boxShadow: YYShadows.surface,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Deliberately bounded: blur is never applied to the whole scrolling page.
class YYGlassSurface extends StatelessWidget {
  const YYGlassSurface({
    super.key,
    required this.height,
    required this.child,
    this.radius = YYRadius.dock,
    this.padding = const EdgeInsets.all(16),
    this.blurSigma,
  }) : assert(height > 0 && height < double.infinity),
       assert(blurSigma == null || blurSigma > 0);
  final double height;
  final Widget child;

  /// Allows bounded navigation surfaces to reuse the same glass implementation.
  final double radius;
  final EdgeInsetsGeometry padding;
  final double? blurSigma;

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context);
    final colors = theme.colors;
    final sigma =
        blurSigma ??
        (MediaQuery.sizeOf(context).shortestSide < 600 ? 30.0 : 34.0);
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.reduceGlass ? colors.elevated : colors.glassFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: theme.reduceGlass ? colors.border : colors.glassStroke,
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            color: colors.glassHighlight,
          ),
          Expanded(
            child: Padding(padding: padding, child: child),
          ),
        ],
      ),
    );
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: YYShadows.floating(theme.brightness),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: theme.reduceGlass
              ? panel
              : BackdropFilter(
                  filter: ui.ImageFilter.compose(
                    outer: const ui.ColorFilter.matrix([
                      1.23622,
                      -.21456,
                      -.02166,
                      0,
                      0,
                      -.06378,
                      1.08544,
                      -.02166,
                      0,
                      0,
                      -.06378,
                      -.21456,
                      1.27834,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ]),
                    inner: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  ),
                  child: panel,
                ),
        ),
      ),
    );
  }
}
