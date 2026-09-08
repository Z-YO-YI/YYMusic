import 'dart:convert';

import '../../domain/models/appearance_settings.dart';
import '../../domain/models/domain_failure.dart';
import '../../domain/repositories/appearance_settings_repository.dart';
import '../database/app_database.dart';

/// Borrows the existing connection and never reads unrelated settings.
final class DriftAppearanceSettingsRepository
    implements AppearanceSettingsRepository {
  DriftAppearanceSettingsRepository(
    this._database, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;
  final AppDatabase _database;
  final DateTime Function() _clock;
  static const keys = [
    'themeMode',
    'accentPreset',
    'customAccent',
    'glassEnabled',
    'reduceMotion',
  ];
  final _pending = <Future<void>>{};
  bool _disposed = false;
  Future<void>? _closeFuture;

  @override
  Future<AppearanceSettings> read() => _run('read', () async {
    final rows = await (_database.select(
      _database.appSettingRecords,
    )..where((row) => row.settingKey.isIn(keys))).get();
    final values = <String, Object?>{};
    for (final row in rows) {
      if (row.valueJson.length > 512) {
        throw const FormatException('Invalid stored appearance');
      }
      values[row.settingKey] = jsonDecode(row.valueJson);
    }
    final mode = values.containsKey('themeMode')
        ? values['themeMode']
        : 'light';
    final accent = values.containsKey('accentPreset')
        ? values['accentPreset']
        : 'coral';
    final color = values['customAccent'];
    final glass = values.containsKey('glassEnabled')
        ? values['glassEnabled']
        : true;
    final motion = values.containsKey('reduceMotion')
        ? values['reduceMotion']
        : false;
    if (mode is! String ||
        accent is! String ||
        (color != null && color is! String) ||
        glass is! bool ||
        motion is! bool) {
      throw const FormatException('Invalid stored appearance');
    }
    return AppearanceSettings(
      mode: AppearanceMode.values.byName(mode),
      accent: AppearanceAccent.values.byName(accent),
      customAccent: color as String?,
      glassEnabled: glass,
      reduceMotion: motion,
    );
  });

  @override
  Future<void> save(AppearanceSettings value) => _run(
    'save',
    () => _database.transaction(() async {
      final timestamp = _clock().toUtc().millisecondsSinceEpoch;
      final values = <String, Object?>{
        'themeMode': value.mode.name,
        'accentPreset': value.accent.name,
        'customAccent': value.customAccent,
        'glassEnabled': value.glassEnabled,
        'reduceMotion': value.reduceMotion,
      };
      for (final entry in values.entries) {
        await _database
            .into(_database.appSettingRecords)
            .insertOnConflictUpdate(
              AppSettingRecordsCompanion.insert(
                settingKey: entry.key,
                valueJson: jsonEncode(entry.value),
                updatedAtMs: timestamp,
              ),
            );
      }
    }),
  );

  Future<T> _run<T>(String operation, Future<T> Function() action) {
    if (_disposed) throw StateError('Appearance repository closed');
    // Register before calling even a reentrant clock or database interceptor.
    final result = Future<T>(() async {
      try {
        return await action();
      } catch (_) {
        throw DomainFailure(
          code: DomainFailureCode.databaseCorrupted,
          diagnosticId: 'appearance.$operation',
          retryable: true,
        );
      }
    });
    late final Future<void> settled;
    settled = result
        .then<void>((_) {}, onError: (Object _) {})
        .whenComplete(() => _pending.remove(settled));
    _pending.add(settled);
    return result;
  }

  @override
  Future<void> dispose() {
    if (_closeFuture != null) return _closeFuture!;
    _disposed = true;
    return _closeFuture = Future.wait<void>(_pending);
  }
}
