import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/app_bootstrap.dart';
import 'package:yymusic/app/app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/domain/repositories/collection_repository.dart';
import 'package:yymusic/domain/repositories/library_repository.dart';
import 'package:yymusic/domain/repositories/lyrics_repository.dart';
import 'package:yymusic/domain/repositories/music_source_repository.dart';
import 'package:yymusic/platform/contracts/secure_credential_gateway.dart';
import 'package:yymusic/playback/audio_engine.dart';

import '../support/close_graph.dart';
import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';

void main() {
  testWidgets('bootstrap shows loading, then owns and disposes injected data', (
    tester,
  ) async {
    final completer = Completer<AppDataServices>();
    final services = _FakeAppDataServices();
    await tester.pumpWidget(
      AppBootstrap(
        platform: YYPlatform.windows,
        dataServicesFactory: (_) => completer.future,
        audioEngineFactory: (_) async => FakeAudioEngine(),
      ),
    );
    expect(find.text('YYMusic 正在准备应用'), findsOneWidget);

    completer.complete(services);
    await tester.pumpAndSettle();
    expect(find.text('YYMusic 正在准备应用'), findsNothing);
    expect(find.byType(YYMusicApp), findsOneWidget);

    final graph = ProviderScope.containerOf(
      tester.element(find.byType(YYMusicApp)),
    ).read(dependencyGraphProvider);
    await tester.pumpWidget(const SizedBox.shrink());
    await closeGraph(tester, graph);
    await tester.pumpAndSettle();
    expect(services.disposeCount, 1);
  });

  testWidgets('bootstrap reports a fixed log-safe initialization failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      AppBootstrap(
        platform: YYPlatform.android,
        dataServicesFactory: (_) async =>
            throw StateError('private-database-path-marker'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('YYMusic 无法初始化应用'), findsOneWidget);
    expect(find.textContaining('private-database-path-marker'), findsNothing);
  });

  testWidgets('late data completion is disposed after bootstrap unmounts', (
    tester,
  ) async {
    final completer = Completer<AppDataServices>();
    final services = _FakeAppDataServices();
    await tester.pumpWidget(
      AppBootstrap(
        platform: YYPlatform.windows,
        dataServicesFactory: (_) => completer.future,
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    completer.complete(services);
    await tester.pump();

    expect(services.disposeCount, 1);
  });

  for (final platform in YYPlatform.values) {
    testWidgets('one $platform audio scope survives resize without autoplay', (
      tester,
    ) async {
      final engine = FakeAudioEngine();
      final services = _FakeAppDataServices();
      var audioCalls = 0;
      await tester.pumpWidget(
        AppBootstrap(
          platform: platform,
          dataServicesFactory: (_) async => services,
          audioEngineFactory: (target) async {
            expect(target, platform);
            audioCalls++;
            return engine;
          },
        ),
      );
      await tester.pumpAndSettle();
      final app = tester.element(find.byType(YYMusicApp));
      final graph = ProviderScope.containerOf(app)
          .read(dependencyGraphProvider);
      expect(graph.playback.isAvailable, isTrue);
      expect(engine.calls, isEmpty);
      tester.view.physicalSize = const Size(1100, 800);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpAndSettle();
      expect(
        ProviderScope.containerOf(tester.element(find.byType(YYMusicApp)))
            .read(dependencyGraphProvider),
        same(graph),
      );
      expect(audioCalls, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await closeGraph(tester, graph);
      await tester.pumpAndSettle();
      expect(engine.disposalCount, 1);
      expect(services.disposeCount, 1);
    });
  }

  testWidgets('audio factory failure releases data and hides private errors', (
    tester,
  ) async {
    final services = _FakeAppDataServices();
    await tester.pumpWidget(
      AppBootstrap(
        platform: YYPlatform.android,
        dataServicesFactory: (_) async => services,
        audioEngineFactory: (_) async =>
            throw StateError('private-audio-marker'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('YYMusic 无法初始化应用'), findsOneWidget);
    expect(find.textContaining('private-audio-marker'), findsNothing);
    expect(services.disposeCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late audio completion releases both acquired resources once', (
    tester,
  ) async {
    final pending = Completer<AudioEngine>();
    final engine = FakeAudioEngine();
    final services = _FakeAppDataServices();
    await tester.pumpWidget(
      AppBootstrap(
        platform: YYPlatform.windows,
        dataServicesFactory: (_) async => services,
        audioEngineFactory: (_) => pending.future,
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(engine);
    await tester.pumpAndSettle();
    expect(engine.disposalCount, 1);
    expect(services.disposeCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'graph construction failure continues cleanup after engine error',
    (tester) async {
      final engine = FakeAudioEngine()
        ..stateStreamError = StateError('private-stream-marker')
        ..disposeError = StateError('private-dispose-marker');
      final services = _FakeAppDataServices();
      await tester.pumpWidget(
        AppBootstrap(
          platform: YYPlatform.android,
          dataServicesFactory: (_) async => services,
          audioEngineFactory: (_) async => engine,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('YYMusic 无法初始化应用'), findsOneWidget);
      expect(find.textContaining('private-'), findsNothing);
      expect(engine.disposalCount, 1);
      expect(services.disposeCount, 1);
      expect(tester.takeException(), isNull);
    },
  );
}

final class _FakeAppDataServices implements AppDataServices {
  @override
  final LibraryRepository library = FakeLibraryRepository();

  @override
  final CollectionRepository collection = FakeCollectionRepository();

  @override
  final LyricsRepository lyrics = FakeLyricsRepository();

  @override
  final MusicSourceRepository musicSources = FakeMusicSourceRepository();

  @override
  final SecureCredentialGateway credentials = FakeSecureCredentialGateway();

  int disposeCount = 0;

  @override
  Future<void> dispose() async {
    disposeCount += 1;
    await library.dispose();
    await (collection as FakeCollectionRepository).dispose();
    await (musicSources as FakeMusicSourceRepository).dispose();
  }
}
