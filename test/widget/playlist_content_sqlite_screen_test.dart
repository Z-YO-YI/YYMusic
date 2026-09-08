import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/playlist_location.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/data/database/app_database.dart';

import '../support/catalog_detail_probe.dart';
import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/fake_audio_engine.dart';
import '../support/fake_playback_dependencies.dart';
import '../support/playlist_content_harness.dart';
import '../support/playlist_content_probe.dart';

void main() {
  setUpAll(loadDesignAssets);
  testWidgets(
    'whole-playlist button persists all 205 SQLite entries in the single root queue',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final track = detailTrack('stored');
      final engine = FakeAudioEngine();
      final graph = (await tester.runAsync(() async {
        final services = await DatabaseAppDataServices.open(
          AppDatabase(NativeDatabase.memory()),
        );
        await services.library.upsertTracks([track]);
        await services.collection.createPlaylist(contentPlaylist('sql'));
        await services.collection.replacePlaylistEntries('sql', [
          for (var i = 0; i < 205; i++)
            contentItem('sql', 'e-$i', i, track).entry,
        ]);
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
            initialLocation: playlistLocation('sql').toString(),
          ),
        ),
      );
      await settleContent(tester);
      expect(playlistState(tester).controller.content!.entries.length, 20);
      await tester.tap(find.byKey(const ValueKey('playlist-play-all')));
      await settleContent(tester);
      expect(graph.playback.state.queue.entries.length, 205);
      expect(engine.calls, ['load', 'play']);
      expect(
        (await tester.runAsync(() => graph.collection!.loadQueue()))!
            .entries
            .length,
        205,
      );
      expect(
        (await tester.runAsync(
          () => graph.collection!.getPlaylistEntries('sql'),
        ))!.length,
        205,
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
  testWidgets(
    'native UI moves and removes real SQLite entries without deleting library tracks',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final services = (await tester.runAsync(
        () =>
            DatabaseAppDataServices.open(AppDatabase(NativeDatabase.memory())),
      ))!;
      final track = detailTrack('stored');
      await tester.runAsync(() async {
        await services.library.upsertTracks([track]);
        await services.collection.createPlaylist(contentPlaylist('sql'));
        await services.collection.replacePlaylistEntries('sql', [
          contentItem('sql', 'a', 0, track).entry,
          contentItem('sql', 'b', 1, track).entry,
        ]);
      });
      // Construct and initialize in one real zone: the player's initial Future
      // tails must not depend on fake microtasks while runAsync is waiting.
      final graph = (await tester.runAsync(() async {
        final value = DependencyGraph(
          dataServices: services,
          audioEngine: FakeAudioEngine(),
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
            initialLocation: playlistLocation('sql').toString(),
          ),
        ),
      );
      await settleContent(tester);
      await openEntryMenu(tester, 'b');
      await tester.tap(find.text('上移一位'));
      await settleContent(tester);
      expect(
        playlistState(tester).controller.content!.entries.first.entry.id,
        'b',
      );
      await openEntryMenu(tester, 'a');
      await tester.tap(find.text('从歌单移除'));
      await settleContent(tester);
      expect(playlistState(tester).controller.content!.totalCount, 1);
      final remaining = await tester.runAsync(
        () => services.collection.getPlaylistEntries('sql'),
      );
      expect(remaining!.single.id, 'b');
      expect(
        await tester.runAsync(() => services.library.getTrack(track.ref)),
        isNotNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await closeGraph(tester, graph);
    },
  );
}
