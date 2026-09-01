import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'yy_theme.dart';

/// Flat CSS fixtures, not albums or user media. Real artwork takes priority.
enum YYArtworkKind { orbit, tide, noon, mono, signal, quiet, local }

/// Clipping radii from POLISH_CSS for the eventual consumers.
enum YYArtworkRole {
  album(20),
  track(10),
  queue(10),
  miniPlayer(12),
  desktopPlayer(14),
  player(26),
  lyricsDock(13);

  const YYArtworkRole(this.radius);
  final double radius;
}

/// Reproduces the original CSS shapes; never downloads or invents cover art.
class YYArtworkPlaceholder extends StatelessWidget {
  const YYArtworkPlaceholder({
    super.key,
    this.kind = YYArtworkKind.local,
    this.dimension = 96,
    this.role = YYArtworkRole.album,
    this.semanticLabel = '暂无封面',
    this.hovered = false,
    this.radius,
  }) : assert(dimension > 0 && dimension < double.infinity),
       assert(radius == null || (radius >= 0 && radius < double.infinity));
  final YYArtworkKind kind;
  final double dimension;
  final YYArtworkRole role;
  final String semanticLabel;
  final bool hovered;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final resolvedRadius = radius ?? role.radius;
    final shadows = switch (role) {
      YYArtworkRole.album => [
        BoxShadow(
          color: Color(hovered ? 0x300F1214 : 0x210F1214),
          offset: Offset(0, hovered ? 16 : 10),
          blurRadius: hovered ? 34 : 26,
        ),
      ],
      YYArtworkRole.player => [
        BoxShadow(
          color: dark ? const Color(0x75000000) : const Color(0x330F1214),
          offset: Offset(0, dark ? 24 : 22),
          blurRadius: dark ? 58 : 50,
        ),
      ],
      YYArtworkRole.miniPlayer || YYArtworkRole.desktopPlayer => const [
        BoxShadow(
          color: Color(0x2B0F1214),
          offset: Offset(0, 7),
          blurRadius: 18,
        ),
      ],
      YYArtworkRole.lyricsDock => const [
        BoxShadow(
          color: Color(0x38000000),
          offset: Offset(0, 10),
          blurRadius: 26,
        ),
      ],
      YYArtworkRole.track || YYArtworkRole.queue => <BoxShadow>[],
    };
    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: dimension,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(resolvedRadius),
            boxShadow: shadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(resolvedRadius),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _ArtworkPainter(kind, theme.accent.color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtworkPainter extends CustomPainter {
  const _ArtworkPainter(this.kind, this.accent);
  final YYArtworkKind kind;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Rect rect(double x, double y, double w, double h) =>
        Rect.fromLTWH(x * s, y * s, w * s, h * s);
    void shape(
      Rect bounds,
      Color color, {
      double radius = 0,
      bool oval = false,
      double rotation = 0,
      double stroke = 0,
    }) {
      canvas.save();
      canvas.translate(bounds.center.dx, bounds.center.dy);
      canvas.rotate(rotation * math.pi / 180);
      var local = Rect.fromCenter(
        center: Offset.zero,
        width: bounds.width,
        height: bounds.height,
      );
      final paint = Paint()..color = color;
      if (stroke > 0) {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke;
        local = local.deflate(stroke / 2);
      }
      if (oval) {
        canvas.drawOval(local, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            local,
            Radius.circular(math.max(0, radius - stroke / 2)),
          ),
          paint,
        );
      }
      canvas.restore();
    }

    final background = switch (kind) {
      YYArtworkKind.orbit => const Color(0xFF0D0F12),
      YYArtworkKind.tide => const Color(0xFF0468C4),
      YYArtworkKind.noon => const Color(0xFFE9DDC8),
      YYArtworkKind.mono => const Color(0xFF0C2030),
      YYArtworkKind.signal => const Color(0xFFF0A018),
      YYArtworkKind.quiet => const Color(0xFFF2EEE8),
      YYArtworkKind.local => const Color(0xFF1A1E24),
    };
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    switch (kind) {
      case YYArtworkKind.orbit:
        shape(rect(-.14, .10, .80, .80), const Color(0xFFC42230), oval: true);
        shape(rect(.61, .58, .30, .30), const Color(0xFFECE7DC), oval: true);
      case YYArtworkKind.tide:
        shape(
          rect(.21, -.07, .22, 1.14),
          const Color(0xFFEDF2F8),
          rotation: 10,
        );
        shape(rect(.52, .10, .40, .40), const Color(0xFFFFA820), oval: true);
      case YYArtworkKind.noon:
        shape(
          rect(.22, .20, .56, .56),
          const Color(0xFF13171B),
          radius: s * .56 * .11,
          rotation: 18,
        );
        shape(rect(.44, .08, .13, .84), const Color(0xFFC83828), rotation: -26);
      case YYArtworkKind.mono:
        shape(
          rect(.09, .32, .82, .36),
          const Color(0xFF009970),
          oval: true,
          rotation: -13,
        );
        shape(rect(.63, .63, .25, .25), const Color(0xFFE2E4D8), radius: 5);
      case YYArtworkKind.signal:
        // CSS shadow offsets are fixed logical px, not percentages of the art.
        final bar = rect(.19, .22, .18, .78);
        for (final offset in [
          Offset.zero,
          const Offset(35, -27),
          const Offset(70, -54),
        ]) {
          shape(bar.shift(offset), const Color(0xFF14181C));
        }
        shape(
          rect(.64, .10, .26, .26),
          const Color(0xFFFFF3DE),
          oval: true,
          stroke: 3,
        );
      case YYArtworkKind.quiet:
        shape(rect(.18, .18, .63, .63), const Color(0xFF0F1113), oval: true);
        shape(rect(.10, .45, .80, .11), const Color(0xFFC82826), rotation: -16);
      case YYArtworkKind.local:
        shape(
          rect(.14, .25, .73, .50),
          const Color(0xFFE4E7F0),
          radius: 16,
          stroke: 2.5,
        );
        final bar = rect(.34, .48, .33, .06);
        shape(
          bar.shift(const Offset(0, -17)),
          accent.withValues(alpha: .62),
          radius: 999,
        );
        shape(
          bar.shift(const Offset(0, 17)),
          accent.withValues(alpha: .38),
          radius: 999,
        );
        shape(bar, accent, radius: 999);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArtworkPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      (kind == YYArtworkKind.local && oldDelegate.accent != accent);
}
