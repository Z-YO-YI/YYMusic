import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

enum SgGlyph {
  home,
  discover,
  search,
  library,
  play,
  pause,
  next,
  previous,
  heart,
  settings,
  queue,
  device,
  volume,
  lyrics,
  more,
  user,
  moon,
  sun,
  arrowDown,
  arrowLeft,
  plus,
  folder,
  download,
  check,
  shuffle,
  repeat,
  close,
  windows,
  phone,
  tablet,
  bell,
  filter,
}

class SgIcon extends StatelessWidget {
  const SgIcon(
    this.glyph, {
    super.key,
    this.size = 24,
    this.color,
    this.filled = false,
  });

  final SgGlyph glyph;
  final double size;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _SgIconPainter(
        glyph,
        color ?? DefaultTextStyle.of(context).style.color ?? context.palette.textPrimary,
        filled,
      ),
    );
  }
}

class _SgIconPainter extends CustomPainter {
  const _SgIconPainter(this.glyph, this.color, this.filled);

  final SgGlyph glyph;
  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final paint = Paint()
      ..color = color
      ..strokeWidth = math.max(1.6, s * .075)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final p = Path();
    Offset o(double x, double y) => Offset(x * s, y * s);

    switch (glyph) {
      case SgGlyph.home:
        p.moveTo(.14 * s, .46 * s);
        p.lineTo(.5 * s, .16 * s);
        p.lineTo(.86 * s, .46 * s);
        p.lineTo(.79 * s, .84 * s);
        p.lineTo(.59 * s, .84 * s);
        p.lineTo(.59 * s, .59 * s);
        p.lineTo(.41 * s, .59 * s);
        p.lineTo(.41 * s, .84 * s);
        p.lineTo(.21 * s, .84 * s);
        p.close();
        canvas.drawPath(p, filled ? fill : paint);
        break;
      case SgGlyph.discover:
        canvas.drawCircle(o(.5, .5), .36 * s, paint);
        p.moveTo(.62 * s, .38 * s);
        p.lineTo(.55 * s, .55 * s);
        p.lineTo(.38 * s, .62 * s);
        p.lineTo(.45 * s, .45 * s);
        p.close();
        canvas.drawPath(p, filled ? fill : paint);
        break;
      case SgGlyph.search:
        canvas.drawCircle(o(.43, .43), .26 * s, paint);
        canvas.drawLine(o(.63, .63), o(.84, .84), paint);
        break;
      case SgGlyph.library:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(.18 * s, .16 * s, .18 * s, .68 * s),
            Radius.circular(.05 * s),
          ),
          filled ? fill : paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(.44 * s, .16 * s, .18 * s, .68 * s),
            Radius.circular(.05 * s),
          ),
          filled ? fill : paint,
        );
        canvas.drawLine(o(.7, .2), o(.82, .8), paint);
        break;
      case SgGlyph.play:
        p.moveTo(.35 * s, .23 * s);
        p.lineTo(.79 * s, .5 * s);
        p.lineTo(.35 * s, .77 * s);
        p.close();
        canvas.drawPath(p, fill);
        break;
      case SgGlyph.pause:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(.29 * s, .22 * s, .16 * s, .56 * s),
            Radius.circular(.04 * s),
          ),
          fill,
        );
        break;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(.55 * s, .22 * s, .16 * s, .56 * s),
            Radius.circular(.04 * s),
          ),
          fill,
        );
      case SgGlyph.next:
      case SgGlyph.previous:
        final reverse = glyph == SgGlyph.previous;
        canvas.save();
        if (reverse) {
          canvas.translate(s, 0);
          canvas.scale(-1, 1);
        }
        p.moveTo(.21 * s, .25 * s);
        p.lineTo(.61 * s, .5 * s);
        p.lineTo(.21 * s, .75 * s);
        p.close();
        canvas.drawPath(p, fill);
        canvas.drawLine(o(.72, .25), o(.72, .75), paint);
        canvas.restore();
        break;
      case SgGlyph.heart:
        p.moveTo(.5 * s, .82 * s);
        p.cubicTo(.24 * s, .66 * s, .13 * s, .51 * s, .18 * s, .34 * s);
        p.cubicTo(.24 * s, .15 * s, .43 * s, .18 * s, .5 * s, .31 * s);
        p.cubicTo(.57 * s, .18 * s, .76 * s, .15 * s, .82 * s, .34 * s);
        p.cubicTo(.87 * s, .51 * s, .76 * s, .66 * s, .5 * s, .82 * s);
        canvas.drawPath(p, filled ? fill : paint);
        break;
      case SgGlyph.settings:
        canvas.drawCircle(o(.5, .5), .15 * s, paint);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          canvas.drawLine(
            o(.5 + math.cos(a) * .27, .5 + math.sin(a) * .27),
            o(.5 + math.cos(a) * .38, .5 + math.sin(a) * .38),
            paint,
          );
        }
        break;
      case SgGlyph.queue:
        for (final y in [.28, .5, .72]) {
          canvas.drawLine(o(.2, y), o(.75, y), paint);
          canvas.drawCircle(o(.84, y), .025 * s, fill);
        }
        break;
      case SgGlyph.device:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(.18 * s, .15 * s, .64 * s, .55 * s),
            Radius.circular(.06 * s),
          ),
          paint,
        );
        canvas.drawLine(o(.38, .84), o(.62, .84), paint);
        canvas.drawLine(o(.5, .7), o(.5, .84), paint);
        break;
      case SgGlyph.volume:
        p.moveTo(.18 * s, .42 * s);
        p.lineTo(.34 * s, .42 * s);
        p.lineTo(.53 * s, .25 * s);
        p.lineTo(.53 * s, .75 * s);
        p.lineTo(.34 * s, .58 * s);
        p.lineTo(.18 * s, .58 * s);
        p.close();
        canvas.drawPath(p, paint);
        p.reset();
        p.moveTo(.65 * s, .37 * s);
        p.quadraticBezierTo(.8 * s, .5 * s, .65 * s, .63 * s);
        canvas.drawPath(p, paint);
        break;
      case SgGlyph.lyrics:
        canvas.drawLine(o(.22, .26), o(.78, .26), paint);
        canvas.drawLine(o(.22, .48), o(.66, .48), paint);
        canvas.drawLine(o(.22, .7), o(.56, .7), paint);
        break;
      case SgGlyph.more:
        for (final x in [.25, .5, .75]) {
          canvas.drawCircle(o(x, .5), .055 * s, fill);
        }
        break;
      case SgGlyph.user:
        canvas.drawCircle(o(.5, .35), .18 * s, filled ? fill : paint);
        p.moveTo(.2 * s, .82 * s);
        p.quadraticBezierTo(.5 * s, .55 * s, .8 * s, .82 * s);
        canvas.drawPath(p, paint);
        break;
      case SgGlyph.moon:
        p.moveTo(.68 * s, .18 * s);
        p.cubicTo(.39 * s, .23 * s, .3 * s, .62 * s, .57 * s, .77 * s);
        p.cubicTo(.3 * s, .82 * s, .15 * s, .57 * s, .24 * s, .35 * s);
        p.cubicTo(.33 * s, .14 * s, .56 * s, .12 * s, .68 * s, .18 * s);
        canvas.drawPath(p, filled ? fill : paint);
        break;
      case SgGlyph.sun:
        canvas.drawCircle(o(.5, .5), .2 * s, paint);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          canvas.drawLine(
            o(.5 + math.cos(a) * .31, .5 + math.sin(a) * .31),
            o(.5 + math.cos(a) * .4, .5 + math.sin(a) * .4),
            paint,
          );
        }
        break;
      case SgGlyph.arrowDown:
      case SgGlyph.arrowLeft:
        canvas.save();
        if (glyph == SgGlyph.arrowLeft) {
          canvas.translate(0, s);
          canvas.rotate(-math.pi / 2);
        }
        canvas.drawLine(o(.24, .39), o(.5, .65), paint);
        canvas.drawLine(o(.5, .65), o(.76, .39), paint);
        canvas.restore();
        break;
      case SgGlyph.plus:
        canvas.drawLine(o(.5, .2), o(.5, .8), paint);
        canvas.drawLine(o(.2, .5), o(.8, .5), paint);
        break;
      case SgGlyph.folder:
        p.moveTo(.14 * s, .28 * s);
        p.lineTo(.4 * s, .28 * s);
        p.lineTo(.49 * s, .38 * s);
        p.lineTo(.86 * s, .38 * s);
        p.lineTo(.81 * s, .78 * s);
        p.lineTo(.19 * s, .78 * s);
        p.close();
        canvas.drawPath(p, filled ? fill : paint);
        break;
      case SgGlyph.download:
        canvas.drawLine(o(.5, .18), o(.5, .64), paint);
        canvas.drawLine(o(.33, .48), o(.5, .65), paint);
        canvas.drawLine(o(.67, .48), o(.5, .65), paint);
        canvas.drawLine(o(.22, .82), o(.78, .82), paint);
        break;
      case SgGlyph.check:
        canvas.drawLine(o(.2, .51), o(.42, .72), paint);
        canvas.drawLine(o(.42, .72), o(.81, .29), paint);
        break;
      case SgGlyph.shuffle:
        canvas.drawLine(o(.18, .3), o(.32, .3), paint);
        canvas.drawLine(o(.32, .3), o(.68, .7), paint);
        canvas.drawLine(o(.68, .7), o(.82, .7), paint);
        canvas.drawLine(o(.7, .59), o(.82, .7), paint);
        canvas.drawLine(o(.7, .81), o(.82, .7), paint);
        canvas.drawLine(o(.18, .7), o(.32, .7), paint);
        canvas.drawLine(o(.32, .7), o(.68, .3), paint);
        canvas.drawLine(o(.68, .3), o(.82, .3), paint);
        break;
      case SgGlyph.repeat:
        p.moveTo(.2 * s, .38 * s);
        p.quadraticBezierTo(.28 * s, .23 * s, .47 * s, .23 * s);
        p.lineTo(.76 * s, .23 * s);
        p.lineTo(.66 * s, .14 * s);
        canvas.drawPath(p, paint);
        p.reset();
        p.moveTo(.8 * s, .62 * s);
        p.quadraticBezierTo(.72 * s, .77 * s, .53 * s, .77 * s);
        p.lineTo(.24 * s, .77 * s);
        p.lineTo(.34 * s, .86 * s);
        canvas.drawPath(p, paint);
        break;
      case SgGlyph.close:
        canvas.drawLine(o(.24, .24), o(.76, .76), paint);
        canvas.drawLine(o(.76, .24), o(.24, .76), paint);
        break;
      case SgGlyph.windows:
        for (final rect in [
          Rect.fromLTWH(.15 * s, .15 * s, .29 * s, .29 * s),
          Rect.fromLTWH(.56 * s, .15 * s, .29 * s, .29 * s),
          Rect.fromLTWH(.15 * s, .56 * s, .29 * s, .29 * s),
          Rect.fromLTWH(.56 * s, .56 * s, .29 * s, .29 * s),
        ]) {
          canvas.drawRect(rect, filled ? fill : paint);
        }
        break;
      case SgGlyph.phone:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(.28 * s, .1 * s, .44 * s, .8 * s),
            Radius.circular(.09 * s),
          ),
          paint,
        );
        canvas.drawCircle(o(.5, .8), .025 * s, fill);
        break;
      case SgGlyph.tablet:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(.14 * s, .2 * s, .72 * s, .6 * s),
            Radius.circular(.06 * s),
          ),
          paint,
        );
        canvas.drawCircle(o(.78, .5), .022 * s, fill);
        break;
      case SgGlyph.bell:
        p.moveTo(.25 * s, .69 * s);
        p.lineTo(.32 * s, .59 * s);
        p.lineTo(.32 * s, .42 * s);
        p.quadraticBezierTo(.32 * s, .2 * s, .5 * s, .2 * s);
        p.quadraticBezierTo(.68 * s, .2 * s, .68 * s, .42 * s);
        p.lineTo(.68 * s, .59 * s);
        p.lineTo(.75 * s, .69 * s);
        p.close();
        canvas.drawPath(p, paint);
        canvas.drawLine(o(.45, .8), o(.55, .8), paint);
        break;
      case SgGlyph.filter:
        canvas.drawLine(o(.18, .28), o(.82, .28), paint);
        canvas.drawLine(o(.28, .5), o(.72, .5), paint);
        canvas.drawLine(o(.39, .72), o(.61, .72), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _SgIconPainter oldDelegate) {
    return oldDelegate.glyph != glyph ||
        oldDelegate.color != color ||
        oldDelegate.filled != filled;
  }
}
