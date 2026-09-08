import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/system_playlist_location.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/collection_models.dart';

import '../support/catalog_detail_probe.dart';
import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/fake_audio_engine.dart';
import '../support/fake_playback_dependencies.dart';
import '../support/playback_history_probe.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import '../support/playlist_content_probe.dart';
import '../support/system_playlist_harness.dart';
import '../unit/system_playlist_repository_test.dart' show systemQueue;

void main() {
  setUpAll(loadDesignAssets);
  testWidgets(
    'empty recent SQLite page observes confirmed root playback without reopening the route',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final track = detailTrack('recorded-sqlite'), engine = FakeAudioEngine();
      final graph = (await tester.runAsync(() async {
        final services = await DatabaseAppDataServices.open(
          AppDatabase(NativeDatabase.memory()),
        );
        await services.library.upsertTracks([track]);
        await services.collection.saveQueue(
          systemQueue([track.ref], current: 'q-0'),
        );
        final graph = DependencyGraph(
          dataServices: services,
          audioEngine: engine,
          playbackSourceResolver: FakePlaybackSourceResolver(),
        );
        await graph.initialize();
        return graph;
      }))!;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [dependencyGraphProvider.overrideWithValue(graph)],
          child: YYMusicApp(
            platform: YYPlatform.android,
            initialLocation: systemPlaylistLocation(SystemPlaylistType.recent)
                .toString(),
          ),
        ),
      );
      await settleContent(tester);
      final controller = systemState(tester).controller;
      expect(controller.content!.entries, isEmpty);
      await tester.runAsync(graph.playback.play);
      await settleContent(tester);
      expect(controller.content!.entries, isEmpty);
      await tester.runAsync(() async {
        engine.events.add(historyState(100));
        await waitHistory(graph.playback.history);
      });
      await settleContent(tester);
      expect(systemState(tester).controller, same(controller));
      expect(controller.content!.entries.single.reference, track.ref);
      final saved = (await tester.runAsync(
        () => graph.collection!.watchHistory().first,
      ))!;
      expect(saved.single.track, track.ref);
      expect(saved.single.lastPosition, const Duration(milliseconds: 100));
      expect(engine.calls, ['load', 'play']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await closeGraph(tester, graph);
    },
  );

  for (final type in SystemPlaylistType.values) {
    testWidgets(
      '$type real SQLite row reaches the single root player and persists exact queue identity',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final track = detailTrack('sqlite'), engine = FakeAudioEngine();
        final graph = (await tester.runAsync(() async {
          final services = await DatabaseAppDataServices.open(
            AppDatabase(NativeDatabase.memory()),
          );
          await services.library.upsertTracks([track]);
          await services.collection.setFavorite(track.ref, favorite: true);
          await services.collection.recordHistory(
            PlayHistoryEntry(
              id: 'h-0',
              track: track.ref,
              startedAt: contentEpoch,
              lastPosition: Duration.zero,
            ),
          );
          await services.collection.saveQueue(
            systemQueue([track.ref, track.ref], current: 'q-0'),
          );
          final value = DependencyGraph(
            dataServices: services,
            audioEngine: engine,
            playbackSourceResolver: FakePlaybackSourceResolver(),
          );
          await value.initialize();
          return value;
        }))!;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [dependencyGraphProvider.overrideWithValue(graph)],
            child: YYMusicApp(
              platform: YYPlatform.android,
              initialLocation: systemPlaylistLocation(type).toString(),
            ),
          ),
        );
        await settleContent(tester);
        final c = systemState(tester).controller;
        final id = type == SystemPlaylistType.queue
            ? 'q-1'
            : c.content!.entries.first.identity;
        await revealSystemRow(tester, id);
        await tester.tap(systemRow(id));
        await settleContent(tester);
        final queue = (await tester.runAsync(
          () => graph.collection!.loadQueue(),
        ))!;
        expect(queue.entries.map((e) => e.id), ['q-0', 'q-1']);
        expect(
          queue.currentEntryId,
          type == SystemPlaylistType.queue ? 'q-1' : 'q-0',
        );
        expect(engine.calls, ['load', 'play']);
        expect(
          await tester.runAsync(() => graph.collection!.watchPlaylists().first),
          isEmpty,
        );
        expect(
          await tester.runAsync(() => graph.library!.getTrack(track.ref)),
          isNotNull,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await closeGraph(tester, graph);
      },
    );
  }
}
