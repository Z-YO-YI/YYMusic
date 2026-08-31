import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_artwork_placeholder.dart';
import 'package:yymusic/design_system/yy_slider.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/features/design_gallery/gallery_media_controls.dart';

import '../support/design_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);

  testWidgets(
    'seven fixtures paint final App.tsx background colors, not legacy HTML',
    (tester) async {
      final expected = [
        0xFF0D0F12,
        0xFF0468C4,
        0xFFE9DDC8,
        0xFF0C2030,
        0xFFF0A018,
        0xFFF2EEE8,
        0xFF1A1E24,
      ];
      for (final kind in YYArtworkKind.values) {
        await tester.pumpWidget(
          designHarness(
            Center(
              child: RepaintBoundary(
                key: const ValueKey('art'),
                child: YYArtworkPlaceholder(
                  kind: kind,
                  dimension: 100,
                  role: YYArtworkRole.track,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('art')),
        );
        final argb = await tester.runAsync(() async {
          final image = await boundary.toImage();
          try {
            final bytes = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            // Mid-right stays clear of every motif, including Tide's rotated strip.
            final offset = (50 * image.width + 95) * 4;
            return (bytes.getUint8(offset + 3) << 24) |
                (bytes.getUint8(offset) << 16) |
                (bytes.getUint8(offset + 1) << 8) |
                bytes.getUint8(offset + 2);
          } finally {
            image.dispose();
          }
        });
        expect(argb, expected[kind.index], reason: kind.name);
      }
    },
  );

  testWidgets(
    'placeholder sizes, clipping and local accent repaint stay semantic images',
    (tester) async {
      final appearance = YYAppearanceController();
      addTearDown(appearance.dispose);
      final semantics = tester.ensureSemantics();
      try {
        for (final role in YYArtworkRole.values) {
          for (final size in [48.0, 96.0, 192.0]) {
            await tester.pumpWidget(
              designHarness(
                Center(
                  child: YYArtworkPlaceholder(dimension: size, role: role),
                ),
                appearance: appearance,
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.getSize(find.byType(YYArtworkPlaceholder)),
              Size.square(size),
            );
            expect(
              tester.widget<ClipRRect>(find.byType(ClipRRect)).borderRadius,
              BorderRadius.circular(role.radius),
            );
            expect(
              tester
                  .getSemantics(find.bySemanticsLabel('暂无封面'))
                  .flagsCollection
                  .isImage,
              isTrue,
            );
            expect(tester.takeException(), isNull);
          }
        }
        final before = tester
            .widget<CustomPaint>(find.byType(CustomPaint))
            .painter!;
        appearance.setCustomAccent('#FFFFFF');
        await tester.pump();
        final after = tester
            .widget<CustomPaint>(find.byType(CustomPaint))
            .painter!;
        expect(after.shouldRepaint(before), isTrue);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'gallery slider changes only labelled local preview and can be disabled',
    (tester) async {
      await tester.pumpWidget(
        designHarness(
          const Center(
            child: SizedBox(width: 340, child: GalleryMediaControls()),
          ),
          scale: 1.3,
        ),
      );
      final slider = find.byType(YYSlider);
      final bounds = tester.getRect(slider);
      await tester.tapAt(Offset(bounds.right - 1, bounds.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('预览 4:00 · 已提交 4:00 / 4:00'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('disable-demo-slider')));
      await tester.pumpAndSettle();
      expect(tester.widget<YYSlider>(slider).onChanged, isNull);
      await tester.tapAt(Offset(bounds.left + 1, bounds.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('预览 4:00 · 已提交 4:00 / 4:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
