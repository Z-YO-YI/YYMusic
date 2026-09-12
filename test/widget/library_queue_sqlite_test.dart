import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/design_system/yy_context_menu.dart';
import 'package:yymusic/features/library/common/library_controller.dart';

import '../support/catalog_detail_probe.dart';
import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/fake_audio_engine.dart';
import '../support/fake_playback_dependencies.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import 'library_queue_actions_test.dart' show tapQueueFeedback;

void main() {
  setUpAll(loadDesignAssets);
  for (final next in [false, true]) {
    testWidgets(
      'SQLite library menu next=$next rollback/retry keeps durable track and queue',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = AppDatabase(NativeDatabase.memory()),
            track = detailTrack('library-queue-sql');
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
        await tester.pumpWidget(
          ProviderScope(
            overrides: [dependencyGraphProvider.overrideWithValue(graph)],
            child: const YYMusicApp(
              platform: YYPlatform.android,
              initialLocation: '/library',
            ),
          ),
        );
        graph.libraryController.selectCategory(LibraryCategory.tracks);
        await settleContent(tester);
        final row = find.byKey(ValueKey(track.ref));
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        await tester.longPress(row);
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => db.customStatement('''
        CREATE TRIGGER fail_library_queue BEFORE INSERT ON queue_entries
        BEGIN SELECT RAISE(ABORT, 'private-marker'); END
      '''),
        );
        tester.widget<YYContextMenu>(find.byType(YYContextMenu)).onSelected!(
          next ? 'next' : 'queue',
        );
        await settleContent(tester);
        expect(graph.queue.editFailure, isNotNull);
        expect(
          (await tester.runAsync(graph.collection!.loadQueue))!.entries,
          isEmpty,
        );
        expect(find.textContaining('private-marker'), findsNothing);
        await tester.runAsync(
          () => db.customStatement('DROP TRIGGER fail_library_queue'),
        );
        await tapQueueFeedback(tester, '重试队列操作');
        final stored = (await tester.runAsync(graph.collection!.loadQueue))!;
        expect(stored.entries.single.track, track.ref);
        expect(stored.entries.single.id, graph.queue.state.entries.single.id);
        expect(stored.currentEntryId, isNull);
        expect(engine.calls, isEmpty);
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
