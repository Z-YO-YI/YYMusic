import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_icon.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';

/// Load bundled fonts and compile every original SVG, never a network fixture.
Future<void> loadDesignAssets() async {
  for (final (family, asset) in [
    ('Inter', 'assets/fonts/inter/InterVariable.ttf'),
    ('Noto Sans SC', 'assets/fonts/noto_sans_sc/NotoSansSCVariable.ttf'),
  ]) {
    final loader = FontLoader(family)..addFont(rootBundle.load(asset));
    await loader.load();
  }
  for (final glyph in YYGlyph.values) {
    final loader = SvgAssetLoader(glyph.assetPath);
    final picture = await vg.loadPicture(loader, null);
    if (picture.size != const Size(24, 24)) {
      throw StateError('Unexpected SVG viewport: ${glyph.assetName}');
    }
    picture.picture.dispose();
  }
}

Widget designHarness(
  Widget child, {
  YYAppearanceController? appearance,
  double scale = 1,
}) {
  final controller = appearance ?? YYAppearanceController();
  if (appearance == null) addTearDown(controller.dispose);
  return WidgetsApp(
    color: const Color(0xFFF5F5F2),
    debugShowCheckedModeBanner: false,
    builder: (context, _) => ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = controller.resolve(
          MediaQuery.platformBrightnessOf(context),
        );
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: YYAppearanceScope(
            controller: controller,
            child: YYTheme(
              data: theme,
              child: DefaultTextStyle(
                style: YYTypography.text(color: theme.colors.text),
                // Match the real router's Overlay so native selection menus
                // and handles can be exercised without a Material app.
                child: Overlay.wrap(
                  child: ColoredBox(color: theme.colors.base, child: child),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
