import 'package:yymusic/domain/models/appearance_settings.dart';
import 'package:yymusic/domain/repositories/appearance_settings_repository.dart';

final class FakeAppearanceSettingsRepository
    implements AppearanceSettingsRepository {
  AppearanceSettings stored = AppearanceSettings.defaults;
  final saves = <AppearanceSettings>[];
  int reads = 0, disposals = 0;
  Future<AppearanceSettings> Function()? onRead;
  Future<void> Function(AppearanceSettings)? onSave;
  @override
  Future<AppearanceSettings> read() async {
    if (disposals > 0) throw StateError('Fake appearance closed');
    reads++;
    return onRead == null ? stored : onRead!();
  }

  @override
  Future<void> save(AppearanceSettings value) async {
    if (disposals > 0) throw StateError('Fake appearance closed');
    saves.add(value);
    await onSave?.call(value);
    stored = value;
  }

  @override
  Future<void> dispose() async {
    if (disposals == 0) disposals++;
  }
}
