import 'package:flutter/widgets.dart';

import 'yy_tokens.dart';

/// An explicit user choice; System resolves against the current OS brightness.
enum YYThemeMode { light, dark, system }

/// Session-only appearance. Persistence belongs to the later data phase.
final class YYAppearanceController extends ChangeNotifier {
  YYThemeMode _mode = YYThemeMode.light;
  YYAccent _accent = YYAccent.fromPreset(YYAccentPreset.coral);
  bool _reduceMotion = false;
  bool _reduceGlass = false;
  YYThemeMode get mode => _mode;
  YYAccent get accent => _accent;
  bool get reduceMotion => _reduceMotion;
  bool get reduceGlass => _reduceGlass;

  void setMode(YYThemeMode value) {
    if (_mode == value) return;
    _mode = value;
    notifyListeners();
  }

  void setPreset(YYAccentPreset value) {
    if (_accent.preset == value) return;
    _accent = YYAccent.fromPreset(value);
    notifyListeners();
  }

  void setCustomAccent(String value) {
    final next = YYAccent.custom(value);
    if (_accent.originalHex == next.originalHex && _accent.preset == null) {
      return;
    }
    _accent = next;
    notifyListeners();
  }

  void setReduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    notifyListeners();
  }

  void setReduceGlass(bool value) {
    if (_reduceGlass == value) return;
    _reduceGlass = value;
    notifyListeners();
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
