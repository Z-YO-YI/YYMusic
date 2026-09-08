import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_appearance_settings_repository.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/domain/models/appearance_settings.dart';
import 'package:yymusic/domain/models/domain_failure.dart';

import '../support/fake_audio_engine.dart';
import '../support/search_query_probe.dart';
import 'appearance_settings_controller_test.dart' show flushAppearance;

Future<void> insertSetting(AppDatabase db, String key, String json) => db
    .into(db.appSettingRecords)
    .insertOnConflictUpdate(
      AppSettingRecordsCompanion.insert(
        settingKey: key,
        valueJson: json,
        updatedAtMs: 1,
      ),
    );

void main() {
  test('model validates colors, preserves custom input and stays redacted', () {
    expect(AppearanceSettings(), AppearanceSettings.defaults);
    for (final color in ['#abcDEF', 'aBC123', '#000000', '#FFFFFF']) {
      final value = AppearanceSettings(
        accent: AppearanceAccent.custom,
        customAccent: color,
      );
      expect(value.customAccent, color);
      expect(value.toString(), isNot(contains(color)));
      expect(
        value.hashCode,
        AppearanceSettings(
          accent: AppearanceAccent.custom,
          customAccent: color,
        ).hashCode,
      );
    }
    for (final color in [
      '#abc',
      '#12345678',
      'private-marker',
      ' #123456',
      '#123456\n',
    ]) {
      expect(
        () => AppearanceSettings(
          accent: AppearanceAccent.custom,
          customAccent: color,
        ),
        throwsFormatException,
      );
    }
    expect(
      () => AppearanceSettings(accent: AppearanceAccent.custom),
      throwsFormatException,
    );
    expect(AppearanceAccent.values.map((e) => e.name), [
      'coral',
      'cobalt',
      'jade',
      'amber',
      'graphite',
      'custom',
    ]);
  });

  test('empty database returns defaults without inserting rows', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = DriftAppearanceSettingsRepository(db);
    addTearDown(db.close);
    addTearDown(repo.dispose);
    expect(await repo.read(), AppearanceSettings.defaults);
    expect(await db.select(db.appSettingRecords).get(), isEmpty);
  });

  test('legacy single theme key restores while unrelated corrupt JSON is never read', () async {
    final probe = SearchQueryProbe();
    final db = AppDatabase(NativeDatabase.memory().interceptWith(probe));
    final repo = DriftAppearanceSettingsRepository(db);
    addTearDown(db.close);
    addTearDown(repo.dispose);
    await insertSetting(db, 'themeMode', '"dark"');
    await insertSetting(db, 'unrelated-setting', 'not-json-private-marker');
    probe.selects.clear();
    expect(await repo.read(), AppearanceSettings(mode: AppearanceMode.dark));
    expect(probe.selects, hasLength(1));
    expect(probe.selects.single.rows, 1);
    expect(probe.selects.single.args, DriftAppearanceSettingsRepository.keys);
  });

  test(
    'five-field save is one transaction and retains unrelated setting bytes',
    () async {
      final probe = SearchQueryProbe();
      final db = AppDatabase(NativeDatabase.memory().interceptWith(probe));
      final repo = DriftAppearanceSettingsRepository(
        db,
        clock: () => DateTime.utc(2026, 9, 9),
      );
      addTearDown(db.close);
      addTearDown(repo.dispose);
      await insertSetting(db, 'volume', '0.42');
      final previous = probe.transactionCount;
      final value = AppearanceSettings(
        mode: AppearanceMode.system,
        accent: AppearanceAccent.custom,
        customAccent: '#fFfFfF',
        glassEnabled: false,
        reduceMotion: true,
      );
      await repo.save(value);
      expect(probe.transactionCount - previous, 1);
      expect(await repo.read(), value);
      final rows = await db.select(db.appSettingRecords).get();
      expect(rows, hasLength(6));
      final other = rows.singleWhere((row) => row.settingKey == 'volume');
      expect(other.valueJson, '0.42');
      expect(other.updatedAtMs, 1);
      expect(
        rows
            .where((row) => row.settingKey != 'volume')
            .map((row) => row.updatedAtMs)
            .toSet(),
        {DateTime.utc(2026, 9, 9).millisecondsSinceEpoch},
      );
    },
  );

  test(
    'mid-transaction failure rolls back every appearance key and permits retry',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = DriftAppearanceSettingsRepository(db);
      addTearDown(db.close);
      addTearDown(repo.dispose);
      await repo.save(AppearanceSettings.defaults);
      await db.customStatement(
        "CREATE TRIGGER fail_appearance BEFORE UPDATE ON app_settings WHEN NEW.setting_key = 'glassEnabled' BEGIN SELECT RAISE(ABORT, 'private-marker'); END",
      );
      final value = AppearanceSettings(
        mode: AppearanceMode.dark,
        accent: AppearanceAccent.amber,
        glassEnabled: false,
        reduceMotion: true,
      );
      await expectLater(
        repo.save(value),
        throwsA(
          isA<DomainFailure>().having(
            (e) => e.toString(),
            'safe',
            isNot(contains('private-marker')),
          ),
        ),
      );
      expect(await repo.read(), AppearanceSettings.defaults);
      await db.customStatement('DROP TRIGGER fail_appearance');
      await repo.save(value);
      expect(await repo.read(), value);
    },
  );

  test('invalid stored types, unknown enums and malformed colors fail without rewriting', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = DriftAppearanceSettingsRepository(db);
    addTearDown(db.close);
    addTearDown(repo.dispose);
    for (final (key, value) in [
      ('themeMode', '"private-marker"'),
      ('themeMode', 'null'),
      ('themeMode', '12'),
      ('accentPreset', '"retired-preset"'),
      ('customAccent', '"private-marker"'),
      ('customAccent', '[]'),
      ('glassEnabled', '1'),
      ('reduceMotion', '"false"'),
      ('themeMode', jsonEncode('x' * 513)),
      ('reduceMotion', 'not-json'),
    ]) {
      await db.delete(db.appSettingRecords).go();
      await insertSetting(db, key, value);
      await expectLater(
        repo.read(),
        throwsA(
          isA<DomainFailure>().having(
            (e) => e.toString(),
            'safe',
            isNot(contains('private-marker')),
          ),
        ),
      );
      expect(
        (await db.select(db.appSettingRecords).getSingle()).valueJson,
        value,
      );
    }
    await db.delete(db.appSettingRecords).go();
    await insertSetting(db, 'accentPreset', '"custom"');
    await expectLater(repo.read(), throwsA(isA<DomainFailure>()));
  });

  test(
    'repository disposal waits for accepted SELECT and does not own database',
    () async {
      final probe = SearchQueryProbe();
      final db = AppDatabase(NativeDatabase.memory().interceptWith(probe));
      final repo = DriftAppearanceSettingsRepository(db);
      addTearDown(db.close);
      await repo.read();
      final gate = Completer<void>(), entered = Completer<void>();
      probe.afterSelect = () async {
        entered.complete();
        await gate.future;
      };
      final reading = repo.read();
      await entered.future;
      var closed = false;
      final closing = repo.dispose().then((_) => closed = true);
      expect(repo.dispose(), same(repo.dispose()));
      await flushAppearance();
      expect(closed, isFalse);
      expect(() => repo.read(), throwsStateError);
      gate.complete();
      await reading;
      await closing;
      expect(probe.closeCount, 0);
    },
  );

  test('a clock may close the repository reentrantly without abandoning its transaction', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    late DriftAppearanceSettingsRepository repo;
    Future<void>? closing;
    repo = DriftAppearanceSettingsRepository(
      db,
      clock: () {
        closing = repo.dispose();
        return DateTime.utc(2026);
      },
    );
    await repo.save(AppearanceSettings.defaults);
    await closing;
    expect(await db.select(db.appSettingRecords).get(), hasLength(5));
    expect(() => repo.save(AppearanceSettings.defaults), throwsStateError);
  });

  test('actual root close drains delayed SQLite INSERT before closing shared scope', () async {
    final probe = SearchQueryProbe();
    final db = AppDatabase(NativeDatabase.memory().interceptWith(probe));
    final services = await DatabaseAppDataServices.open(db);
    final engine = FakeAudioEngine();
    final graph = DependencyGraph(dataServices: services, audioEngine: engine);
    await graph.initialize();
    expect(
      graph.appearanceSettings.repository,
      same(services.appearanceSettings),
    );
    final gate = Completer<void>(), entered = Completer<void>();
    probe.beforeInsert = () async {
      if (!entered.isCompleted) entered.complete();
      await gate.future;
    };
    graph.appearance.setMode(YYThemeMode.dark);
    await entered.future;
    var closed = false;
    final closing = graph.close().then((_) => closed = true);
    await flushAppearance();
    expect(closed, isFalse);
    expect(probe.closeCount, 0);
    gate.complete();
    await closing;
    expect(probe.closeCount, 1);
    expect(engine.calls.where((e) => e == 'play'), isEmpty);
  });

  test('actual database and root recreation restores final custom settings after restart', () async {
    final directory = await Directory.systemTemp.createTemp(
      'yymusic-appearance-',
    );
    addTearDown(() async {
      final parent = Directory.systemTemp.absolute.path;
      expect(
        directory.absolute.path.startsWith('$parent${Platform.pathSeparator}'),
        isTrue,
      );
      await directory.delete(recursive: true);
    });
    final file = File(
      '${directory.path}${Platform.pathSeparator}appearance.sqlite',
    );
    final services = await DatabaseAppDataServices.open(
      AppDatabase(NativeDatabase(file)),
    );
    final first = DependencyGraph(dataServices: services);
    await first.initialize();
    first.appearance.setMode(YYThemeMode.system);
    first.appearance.setCustomAccent('#AaBBcC');
    first.appearance.setReduceGlass(true);
    first.appearance.setReduceMotion(true);
    await first.close();
    final reopened = await DatabaseAppDataServices.open(
      AppDatabase(NativeDatabase(file)),
    );
    final second = DependencyGraph(dataServices: reopened);
    await second.initialize();
    expect(second.appearance.mode, YYThemeMode.system);
    expect(second.appearance.accent.originalHex, '#AaBBcC');
    expect(second.appearance.reduceGlass, isTrue);
    expect(second.appearance.reduceMotion, isTrue);
    expect(second.appearanceSettings.unsaved, isFalse);
    await second.close();
  });
}
