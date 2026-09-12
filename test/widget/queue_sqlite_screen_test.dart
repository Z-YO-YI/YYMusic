import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/data/database/app_database.dart';

import '../support/catalog_detail_probe.dart';
import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/fake_audio_engine.dart';
import '../support/fake_playback_dependencies.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import '../unit/system_playlist_repository_test.dart' show systemQueue;
import 'queue_screen_test.dart' show queuePage, tile;

void main() {
  setUpAll(loadDesignAssets);
  for (final fails in [false, true]) {
    testWidgets(
      'real SQLite exact play, root rebind, edit and clear; rollback=$fails',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final database = AppDatabase(NativeDatabase.memory());
        final track = detailTrack('queue-sqlite'), engine = FakeAudioEngine();
        final graph = (await tester.runAsync(() async {
          final services = await DatabaseAppDataServices.open(database);
          await services.library.upsertTracks([track]);
          await services.collection.saveQueue(
            systemQueue([track.ref, track.ref], current: 'q-0'),
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
            child: const YYMusicApp(
              platform: YYPlatform.android,
              initialLocation: '/queue',
            ),
          ),
        );
        await settleContent(tester);
        tile(tester, 'q-1').onPressed!();
        await settleContent(tester);
        expect(engine.calls, ['load', 'play']);
        expect(graph.queue.state.currentEntryId, 'q-1');
        final page = queuePage(tester).controller;
        expect(page.canEdit(page.read.content!), isTrue);
        tile(tester, 'q-1').onMoveUp!();
        await settleContent(tester);
        expect(
          (await tester.runAsync(graph.collection!.loadQueue))!
              .entries
              .first
              .id,
          'q-1',
        );
        expect(page.canEdit(page.read.content!), isTrue);
        if (fails) {
          await tester.runAsync(
            () => database.customStatement('''
          CREATE TRIGGER fail_queue_page BEFORE INSERT ON queue_entries
          BEGIN SELECT RAISE(ABORT, 'private-marker'); END
        '''),
          );
        }
        tile(tester, 'q-0').onRemove!();
        await settleContent(tester);
        if (fails) {
          expect(find.text('队列操作未完成'), findsOneWidget);
          expect(find.textContaining('private-marker'), findsNothing);
          expect(
            (await tester.runAsync(graph.collection!.loadQueue))!.entries,
            hasLength(2),
          );
          await tester.runAsync(
            () => database.customStatement('DROP TRIGGER fail_queue_page'),
          );
          await tester.tap(find.text('重试队列操作'));
          await settleContent(tester);
        }
        expect(
          (await tester.runAsync(graph.collection!.loadQueue))!
              .entries
              .single
              .id,
          'q-1',
        );
        expect(engine.calls, ['load', 'play']);
        await tester.tap(find.text('清空'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('确认清空'));
        await settleContent(tester);
        expect(
          (await tester.runAsync(graph.collection!.loadQueue))!.entries,
          isEmpty,
        );
        expect(
          await tester.runAsync(() => graph.library!.getTrack(track.ref)),
          isNotNull,
        );
        expect(engine.calls, ['load', 'play', 'stop']);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await closeGraph(tester, graph);
      },
    );
  }
}
