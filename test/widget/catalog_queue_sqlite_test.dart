import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/catalog_detail_location.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/catalog_browse.dart';
import 'package:yymusic/domain/models/catalog_reference.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_state.dart';

import '../support/catalog_detail_harness.dart' show detailState;
import '../support/catalog_detail_menu_harness.dart';
import '../support/catalog_detail_probe.dart';
import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/fake_audio_engine.dart';
import '../support/fake_playback_dependencies.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import 'library_queue_actions_test.dart' show tapQueueFeedback;

void main() {
  setUpAll(loadDesignAssets);
  for (final artist in [false, true]) {
    for (final next in [false, true]) {
      testWidgets(
        'SQLite detail artist=$artist next=$next fails atomically and retries one durable reference',
        (tester) async {
          tester.view.physicalSize = const Size(390, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final db = AppDatabase(NativeDatabase.memory());
          final track = detailTrack('catalog-queue-sql');
          final engine = FakeAudioEngine();
          final graph = (await tester.runAsync(() async {
            final services = await DatabaseAppDataServices.open(db);
            await services.library.upsertTracks([track]);
            final graph = DependencyGraph(
              dataServices: services,
              audioEngine: engine,
              playbackSourceResolver: FakePlaybackSourceResolver(),
            );
            await graph.initialize();
            return graph;
          }))!;
          try {
            final CatalogDetailTarget target;
            if (artist) {
              final artists = (await tester.runAsync(
                () => graph.catalogBrowse!.browseArtists(
                  const CatalogArtistQuery(),
                  PageRequest(limit: 1),
                ),
              ))!;
              target = ArtistDetailTarget(artists.items.single.ref);
            } else {
              target = AlbumDetailTarget(
                AlbumRef(sourceId: track.sourceId, albumId: track.albumId!),
              );
            }
            await tester.pumpWidget(
              ProviderScope(
                overrides: [dependencyGraphProvider.overrideWithValue(graph)],
                child: YYMusicApp(
                  platform: YYPlatform.android,
                  initialLocation: catalogDetailLocation(target).toString(),
                ),
              ),
            );
            await settleContent(tester);
            final loaded = detailState(tester).controller.tracks.items.single;
            expect(loaded.ref, track.ref);
            await openDetailMenu(tester, loaded);
            await tester.runAsync(
              () => db.customStatement('''
          CREATE TRIGGER fail_catalog_queue BEFORE INSERT ON queue_entries
          BEGIN SELECT RAISE(ABORT, 'private-marker'); END
        '''),
            );
            await tester.tap(find.text(next ? '下一首播放' : '添加到队列'));
            await settleContent(tester);
            final failure = graph.queue.editFailure!;
            expect(
              (await tester.runAsync(graph.collection!.loadQueue))!.entries,
              isEmpty,
            );
            expect(find.textContaining('private-marker'), findsNothing);
            await tester.runAsync(
              () => db.customStatement('DROP TRIGGER fail_catalog_queue'),
            );
            await tapQueueFeedback(tester, '重试队列操作');
            final saved = (await tester.runAsync(graph.collection!.loadQueue))!;
            expect(saved.entries.single.track, track.ref);
            expect(
              saved.entries.single.id,
              failure.edit.apply(updatedAt: saved.updatedAt)!.entries.single.id,
            );
            expect(saved.currentEntryId, isNull);
            expect(
              await tester.runAsync(() => graph.library!.getTrack(track.ref)),
              isNotNull,
            );
            expect(engine.calls, isEmpty);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await closeGraph(tester, graph);
          }
        },
      );
    }
  }
}
