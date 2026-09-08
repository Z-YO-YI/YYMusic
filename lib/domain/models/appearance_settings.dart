/// Stable storage values, independent of Flutter and platform plugins.
enum AppearanceMode { light, dark, system }

/// The five audited presets plus an explicitly validated custom color.
enum AppearanceAccent { coral, cobalt, jade, amber, graphite, custom }

/// A complete immutable appearance snapshot. No arbitrary settings or secrets.
final class AppearanceSettings {
  factory AppearanceSettings({
    AppearanceMode mode = AppearanceMode.light,
    AppearanceAccent accent = AppearanceAccent.coral,
    String? customAccent,
    bool glassEnabled = true,
    bool reduceMotion = false,
  }) {
    if (customAccent != null &&
        !RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(customAccent)) {
      throw const FormatException('Invalid appearance color');
    }
    if (accent == AppearanceAccent.custom && customAccent == null) {
      throw const FormatException('Custom appearance color required');
    }
    return AppearanceSettings._(
      mode,
      accent,
      accent == AppearanceAccent.custom ? customAccent : null,
      glassEnabled,
      reduceMotion,
    );
  }

  const AppearanceSettings._(
    this.mode,
    this.accent,
    this.customAccent,
    this.glassEnabled,
    this.reduceMotion,
  );
  static const defaults = AppearanceSettings._(
    AppearanceMode.light,
    AppearanceAccent.coral,
    null,
    true,
    false,
  );
  final AppearanceMode mode;
  final AppearanceAccent accent;
  final String? customAccent;
  final bool glassEnabled;
  final bool reduceMotion;

  @override
  bool operator ==(Object other) =>
      other is AppearanceSettings &&
      mode == other.mode &&
      accent == other.accent &&
      customAccent == other.customAccent &&
      glassEnabled == other.glassEnabled &&
      reduceMotion == other.reduceMotion;
  @override
  int get hashCode =>
      Object.hash(mode, accent, customAccent, glassEnabled, reduceMotion);
  @override
  String toString() => 'AppearanceSettings(<redacted>)';
}
