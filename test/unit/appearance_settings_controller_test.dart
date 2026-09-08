import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';
import 'package:yymusic/domain/models/appearance_settings.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/features/settings/common/appearance_settings_controller.dart';

import '../support/fake_appearance_settings_repository.dart';

Future<void> flushAppearance() => pumpEventQueue(times: 30);

void main() {
  late YYAppearanceController appearance;
  late FakeAppearanceSettingsRepository repository;
  late AppearanceSettingsController controller;
  setUp(() {
    appearance = YYAppearanceController();
    repository = FakeAppearanceSettingsRepository();
    controller = AppearanceSettingsController(
      appearance: appearance,
      repository: repository,
    );
  });
  tearDown(() async {
    await controller.close();
    appearance.dispose();
    await repository.dispose();
  });

  test('constructor performs no I/O; initial restoration is atomic and never writes', () async {
    repository.stored = AppearanceSettings(
      mode: AppearanceMode.dark,
      accent: AppearanceAccent.jade,
      glassEnabled: false,
      reduceMotion: true,
    );
    await flushAppearance();
    expect(repository.reads, 0);
    var changes = 0;
    appearance.addListener(() => changes++);
    final first = controller.initialize();
    expect(controller.initialize(), same(first));
    await first;
    expect(changes, 1);
    expect(appearance.mode, YYThemeMode.dark);
    expect(appearance.accent.preset, YYAccentPreset.jade);
    expect(appearance.reduceGlass, isTrue);
    expect(appearance.reduceMotion, isTrue);
    expect(controller.ready, isTrue);
    expect(controller.unsaved, isFalse);
    expect(repository.saves, isEmpty);
  });

  test('all modes and audited accents map to the same visual types', () async {
    for (final mode in AppearanceMode.values) {
      for (final accent in AppearanceAccent.values) {
        final visual = YYAppearanceController();
        final data = FakeAppearanceSettingsRepository()
          ..stored = AppearanceSettings(
            mode: mode,
            accent: accent,
            customAccent: accent == AppearanceAccent.custom ? '#abC123' : null,
          );
        final bridge = AppearanceSettingsController(
          appearance: visual,
          repository: data,
        );
        await bridge.initialize();
        expect(visual.mode.name, mode.name);
        expect(visual.accent.preset?.name ?? 'custom', accent.name);
        if (accent == AppearanceAccent.custom) {
          expect(visual.accent.originalHex, '#abC123');
        }
        final theme = visual.resolve(Brightness.dark, systemReduceMotion: true);
        expect(theme.reduceMotion, isTrue);
        expect(
          YYAccent.contrast(theme.accent.color, theme.accent.onAccent),
          greaterThanOrEqualTo(4.5),
        );
        expect(data.saves, isEmpty);
        await bridge.close();
        visual.dispose();
        await data.dispose();
      }
    }
  });

  for (final before in [true, false]) {
    test(
      'user edit ${before ? 'before' : 'during'} startup wins over late saved value',
      () async {
        final gate = Completer<AppearanceSettings>();
        repository.onRead = () => gate.future;
        if (before) appearance.setPreset(YYAccentPreset.amber);
        final starting = controller.initialize();
        await flushAppearance();
        if (!before) appearance.setPreset(YYAccentPreset.amber);
        gate.complete(AppearanceSettings(mode: AppearanceMode.dark));
        await starting;
        expect(appearance.mode, YYThemeMode.light);
        expect(appearance.accent.preset, YYAccentPreset.amber);
        expect(repository.stored.accent, AppearanceAccent.amber);
        expect(repository.saves, hasLength(1));
      },
    );
  }

  test(
    'rapid edits serialize and coalesce to the latest full snapshot',
    () async {
      await controller.initialize();
      final gate = Completer<void>();
      var active = 0, maximum = 0;
      repository.onSave = (_) async {
        active++;
        if (active > maximum) maximum = active;
        if (repository.saves.length == 1) await gate.future;
        active--;
      };
      appearance.setMode(YYThemeMode.dark);
      await flushAppearance();
      expect(controller.saving, isTrue);
      for (var i = 0; i < 30; i++) {
        appearance.setReduceGlass(i.isEven);
      }
      appearance.setCustomAccent('12aBcD');
      appearance.setReduceMotion(true);
      expect(repository.saves, hasLength(1));
      gate.complete();
      await flushAppearance();
      expect(repository.saves, hasLength(2));
      expect(maximum, 1);
      expect(repository.stored.customAccent, '12aBcD');
      expect(repository.stored.reduceMotion, isTrue);
      expect(controller.unsaved, isFalse);
    },
  );

  test('load failure never overwrites storage; explicit retry preserves early edits', () async {
    repository.onRead = () async => throw StateError('private-marker');
    await controller.initialize();
    expect(controller.phase, LoadPhase.error);
    expect(controller.failure.toString(), isNot(contains('private-marker')));
    appearance.setMode(YYThemeMode.dark);
    await flushAppearance();
    expect(repository.saves, isEmpty);
    expect(repository.reads, 1);
    repository.onRead = null;
    controller.retry();
    await flushAppearance();
    expect(repository.reads, 2);
    expect(repository.stored.mode, AppearanceMode.dark);
    expect(controller.failure, isNull);
  });

  test(
    'failed save retains current UI and explicit retry saves latest value',
    () async {
      await controller.initialize();
      repository.onSave = (_) async => throw StateError('private-marker');
      appearance.setMode(YYThemeMode.dark);
      await flushAppearance();
      expect(appearance.mode, YYThemeMode.dark);
      expect(controller.unsaved, isTrue);
      expect(controller.failure!.diagnosticId, 'appearance-settings.save');
      repository.onSave = null;
      controller.retry();
      await flushAppearance();
      expect(repository.stored.mode, AppearanceMode.dark);
      expect(controller.unsaved, isFalse);
    },
  );

  test('newer edit proceeds after an older in-flight save failure', () async {
    await controller.initialize();
    final gate = Completer<void>();
    repository.onSave = (_) async {
      if (repository.saves.length == 1) {
        await gate.future;
        throw StateError('old-failure');
      }
    };
    appearance.setMode(YYThemeMode.dark);
    await flushAppearance();
    appearance.setPreset(YYAccentPreset.cobalt);
    gate.complete();
    await flushAppearance();
    expect(repository.saves, hasLength(2));
    expect(repository.stored.accent, AppearanceAccent.cobalt);
    expect(controller.failure, isNull);
  });

  test(
    'shutdown drains in-flight and coalesced changes but rejects later edits',
    () async {
      await controller.initialize();
      final gate = Completer<void>();
      repository.onSave = (_) async {
        if (repository.saves.length == 1) await gate.future;
      };
      appearance.setMode(YYThemeMode.dark);
      await flushAppearance();
      appearance.setPreset(YYAccentPreset.jade);
      var closed = false;
      final closing = controller.close().then((_) => closed = true);
      expect(controller.close(), same(controller.close()));
      appearance.setMode(YYThemeMode.light);
      await flushAppearance();
      expect(closed, isFalse);
      gate.complete();
      await closing;
      expect(repository.saves, hasLength(2));
      expect(repository.stored.mode, AppearanceMode.dark);
      expect(repository.stored.accent, AppearanceAccent.jade);
      expect(repository.disposals, 0);
    },
  );

  test('close during initial read drains accepted early preference without touching disposed visual state', () async {
    final gate = Completer<AppearanceSettings>();
    repository.onRead = () => gate.future;
    final initializing = controller.initialize();
    appearance.setMode(YYThemeMode.dark);
    final closing = controller.close();
    gate.complete(AppearanceSettings.defaults);
    await initializing;
    await closing;
    expect(repository.stored.mode, AppearanceMode.dark);
    expect(repository.saves, hasLength(1));
  });

  test(
    'save dependency may close reentrantly and shutdown still waits for it',
    () async {
      await controller.initialize();
      final gate = Completer<void>();
      Future<void>? closing;
      repository.onSave = (_) async {
        closing = controller.close();
        await gate.future;
      };
      appearance.setMode(YYThemeMode.dark);
      await flushAppearance();
      expect(closing, isNotNull);
      gate.complete();
      await closing;
      expect(repository.stored.mode, AppearanceMode.dark);
    },
  );

  test(
    'restoration captures a real change made by another appearance listener',
    () async {
      repository.stored = AppearanceSettings(mode: AppearanceMode.dark);
      appearance.addListener(() {
        if (appearance.accent.preset != YYAccentPreset.amber) {
          appearance.setPreset(YYAccentPreset.amber);
        }
      });
      await controller.initialize();
      expect(repository.stored.mode, AppearanceMode.dark);
      expect(repository.stored.accent, AppearanceAccent.amber);
      expect(repository.saves, hasLength(1));
    },
  );

  test('session-only bridge never pretends to be persistent', () async {
    final visual = YYAppearanceController();
    final temporary = AppearanceSettingsController(appearance: visual);
    await temporary.initialize();
    visual.setMode(YYThemeMode.dark);
    expect(temporary.persistent, isFalse);
    expect(temporary.unsaved, isFalse);
    await temporary.close();
    visual.dispose();
  });

  test('root close inside an appearance notification preserves the accepted save safely', () async {
    final data = FakeAppearanceSettingsRepository();
    final graph = DependencyGraph(appearanceRepository: data);
    await graph.initialize();
    Future<void>? closing;
    graph.appearance.addListener(() {
      closing = graph.close();
    });
    graph.appearance.setMode(YYThemeMode.dark);
    await closing;
    expect(data.stored.mode, AppearanceMode.dark);
    graph.appearance.setMode(YYThemeMode.light);
    expect(graph.appearance.mode, YYThemeMode.dark);
    await data.dispose();
  });

  test(
    'shutdown returns a safe failure if an accepted preference cannot save',
    () async {
      final visual = YYAppearanceController();
      final data = FakeAppearanceSettingsRepository()
        ..onSave = (_) async => throw StateError('private-marker');
      final failed = AppearanceSettingsController(
        appearance: visual,
        repository: data,
      );
      await failed.initialize();
      visual.setMode(YYThemeMode.dark);
      await flushAppearance();
      await expectLater(
        failed.close(),
        throwsA(
          isA<DomainFailure>().having(
            (e) => e.diagnosticId,
            'diagnostic',
            'appearance-settings.close',
          ),
        ),
      );
      visual.dispose();
      await data.dispose();
    },
  );
}
