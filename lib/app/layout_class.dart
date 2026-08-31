import 'package:flutter/foundation.dart';

enum YYPlatform {
  windows,
  android;

  static YYPlatform? fromTarget(TargetPlatform target) => switch (target) {
    TargetPlatform.windows => windows,
    TargetPlatform.android => android,
    _ => null,
  };
}

enum YYLayoutClass {
  windowsExpanded,
  windowsStandard,
  windowsNarrow,
  androidPhone,
  androidTabletPortrait,
  androidTabletLandscape,
}

/// Logical pixels from the current LayoutBuilder, never device model names.
YYLayoutClass classifyLayout({
  required YYPlatform platform,
  required double width,
  required double height,
}) {
  if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
    throw ArgumentError('Layout constraints must be finite and positive.');
  }
  if (platform == YYPlatform.windows) {
    if (width >= 1440) return YYLayoutClass.windowsExpanded;
    if (width >= 1024) return YYLayoutClass.windowsStandard;
    return YYLayoutClass.windowsNarrow;
  }
  if (width < 600) return YYLayoutClass.androidPhone;
  return width > height
      ? YYLayoutClass.androidTabletLandscape
      : YYLayoutClass.androidTabletPortrait;
}
