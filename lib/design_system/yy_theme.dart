import 'package:flutter/widgets.dart';

import 'yy_tokens.dart';

/// An explicit user choice; System resolves against the current OS brightness.
enum YYThemeMode { light, dark, system }

/// Shared visual state; the app-owned settings bridge handles persistence.
final class YYAppearanceController extends ChangeNotifier {
  YYThemeMode _mode = YYThemeMode.light;
  YYAccent _accent = YYAccent.fromPreset(YYAccentPreset.coral);
  bool _reduceMotion = false;
  bool _reduceGlass = false;
  bool _disposed = false, _notifierDisposed = false;
  int _notificationDepth = 0;
  YYThemeMode get mode => _mode;
  YYAccent get accent => _accent;
  bool get reduceMotion => _reduceMotion;
  bool get reduceGlass => _reduceGlass;

  /// Restores one validated snapshot with at most one visual notification.
  void restore({
    required YYThemeMode mode,
    required YYAccent accent,
    required bool reduceGlass,
    required bool reduceMotion,
  }) {
    if (_disposed) return;
    if (_mode == mode &&
        _accent.preset == accent.preset &&
        _accent.originalHex == accent.originalHex &&
        _reduceGlass == reduceGlass &&
        _reduceMotion == reduceMotion) {
      return;
    }
    _mode = mode;
    _accent = accent;
    _reduceGlass = reduceGlass;
    _reduceMotion = reduceMotion;
    _notify();
  }

  void setMode(YYThemeMode value) {
    if (_disposed || _mode == value) return;
    _mode = value;
    _notify();
  }

  void setPreset(YYAccentPreset value) {
    if (_disposed || _accent.preset == value) return;
    _accent = YYAccent.fromPreset(value);
    _notify();
  }

  void setCustomAccent(String value) {
    if (_disposed) return;
    final next = YYAccent.custom(value);
    if (_accent.originalHex == next.originalHex && _accent.preset == null) {
      return;
    }
    _accent = next;
    _notify();
  }

  void setReduceMotion(bool value) {
    if (_disposed || _reduceMotion == value) return;
    _reduceMotion = value;
    _notify();
  }

  void setReduceGlass(bool value) {
    if (_disposed || _reduceGlass == value) return;
    _reduceGlass = value;
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    _notificationDepth++;
    try {
      notifyListeners();
    } finally {
      _notificationDepth--;
      if (_disposed) dispose();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (_notifierDisposed || _notificationDepth != 0) return;
    _notifierDisposed = true;
    super.dispose();
  }

  YYThemeData resolve(
    Brightness systemBrightness, {
    bool systemReduceMotion = false,
  }) => YYThemeData(
    brightness: switch (_mode) {
      YYThemeMode.light => Brightness.light,
      YYThemeMode.dark => Brightness.dark,
      YYThemeMode.system => systemBrightness,
    },
    accent: _accent,
    reduceMotion: _reduceMotion || systemReduceMotion,
    reduceGlass: _reduceGlass,
  );
}

@immutable
final class YYThemeData {
  const YYThemeData({
    required this.brightness,
    required this.accent,
    this.reduceMotion = false,
    this.reduceGlass = false,
  });
  final Brightness brightness;
  final YYAccent accent;
  final bool reduceMotion;
  final bool reduceGlass;
  YYPalette get colors => YYPalette(brightness);
  Duration motion(Duration duration) => reduceMotion ? Duration.zero : duration;
}

/// App-owned appearance is available without leaking the DI package into UI.
class YYAppearanceScope extends InheritedNotifier<YYAppearanceController> {
  const YYAppearanceScope({
    super.key,
    required YYAppearanceController controller,
    required super.child,
  }) : super(notifier: controller);
  static YYAppearanceController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<YYAppearanceScope>()!
      .notifier!;
}

class YYTheme extends InheritedWidget {
  const YYTheme({super.key, required this.data, required super.child});
  final YYThemeData data;
  static YYThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<YYTheme>()!.data;
  @override
  bool updateShouldNotify(YYTheme oldWidget) => data != oldWidget.data;
}
