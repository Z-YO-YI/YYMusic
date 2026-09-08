import '../models/appearance_settings.dart';

/// Stores only the typed appearance snapshot. The app scope owns the database.
abstract interface class AppearanceSettingsRepository {
  /// Missing fields use defaults; corrupt fields fail without writing defaults.
  Future<AppearanceSettings> read();

  /// Saves all appearance fields atomically, preserving unrelated settings.
  Future<void> save(AppearanceSettings value);

  /// Rejects new work and waits for accepted reads/writes; idempotent.
  Future<void> dispose();
}
