import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';

void main() {
  final cases = <(YYPlatform, double, double, YYLayoutClass)>[
    (YYPlatform.windows, 1440, 900, YYLayoutClass.windowsExpanded),
    (YYPlatform.windows, 1439, 900, YYLayoutClass.windowsStandard),
    (YYPlatform.windows, 1024, 720, YYLayoutClass.windowsStandard),
    (YYPlatform.windows, 1023, 720, YYLayoutClass.windowsNarrow),
    (YYPlatform.windows, 599, 900, YYLayoutClass.windowsNarrow),
    (YYPlatform.android, 599, 900, YYLayoutClass.androidPhone),
    (YYPlatform.android, 600, 900, YYLayoutClass.androidTabletPortrait),
    (YYPlatform.android, 600, 600, YYLayoutClass.androidTabletPortrait),
    (YYPlatform.android, 844, 390, YYLayoutClass.androidTabletLandscape),
    (YYPlatform.android, 1024, 768, YYLayoutClass.androidTabletLandscape),
    (YYPlatform.android, 1440, 2000, YYLayoutClass.androidTabletPortrait),
  ];
  for (final (platform, width, height, expected) in cases) {
    test('$platform at $width x $height is $expected', () {
      expect(
        classifyLayout(platform: platform, width: width, height: height),
        expected,
      );
    });
  }
  test('invalid constraints are not guessed as a phone', () {
    for (final width in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
        () => classifyLayout(
          platform: YYPlatform.android,
          width: width,
          height: 900,
        ),
        throwsArgumentError,
      );
    }
  });
  test('unsupported OS is not silently classified as Windows', () {
    expect(YYPlatform.fromTarget(TargetPlatform.linux), isNull);
    expect(YYPlatform.fromTarget(TargetPlatform.windows), YYPlatform.windows);
    expect(YYPlatform.fromTarget(TargetPlatform.android), YYPlatform.android);
  });
}
