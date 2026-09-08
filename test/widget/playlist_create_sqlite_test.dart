import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/features/library/common/library_controller.dart';

import '../support/catalog_detail_probe.dart';
import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/fake_audio_engine.dart';
import '../support/fake_playback_dependencies.dart';
import '../support/playlist_add_harness.dart';
import '../support/playlist_content_harness.dart';
import 'playlist_create_and_add_test.dart' show enterNewName;

void main() {
  setUpAll(loadDesignAssets);
  testWidgets(
    'real SQLite failed first-entry insertion leaves no playlist and explicit UI retry creates a complete pair',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      final services = (await tester.runAsync(
        () => DatabaseAppDataServices.open(db),
      ))!;
      final track = detailTrack('stored');
      await tester.runAsync(() async {
        await services.library.upsertTracks([track]);
        await db.customStatement(
          "CREATE TRIGGER fail_first AFTER INSERT ON playlist_entries BEGIN SELECT RAISE(ABORT, 'private-marker'); END",
        );
      });
      final engine = FakeAudioEngine();
      final graph = (await tester.runAsync(() async {
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
          child: const YYMusicApp(
            platform: YYPlatform.android,
            initialLocation: '/library',
          ),
        ),
      );
      await settleContent(tester);
      graph.libraryController.selectCategory(LibraryCategory.tracks);
      await settleContent(tester);
      final row = find.byKey(ValueKey(track.ref));
      await tester.ensureVisible(row);
      await tester.longPress(row);
      await tester.pumpAndSettle();
      await tester.tap(find.text('添加到歌单'));
      await settleContent(tester);
      await enterNewName(tester, '完整保存');
      await tester.ensureVisible(pickerButton('新建并添加'));
      await tester.tap(pickerButton('新建并添加'));
      await settleContent(tester);
      expect(find.text('添加未完成'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      final afterFailure = await tester.runAsync(
        () async => (
          await db.select(db.playlistRecords).get(),
          await db.select(db.playlistEntryRecords).get(),
        ),
      );
      expect(afterFailure!.$1, isEmpty);
      expect(afterFailure.$2, isEmpty);
      expect(pickerState(tester).nameInput.text, '完整保存');
      await tester.runAsync(
        () => db.customStatement('DROP TRIGGER fail_first'),
      );
      await tester.ensureVisible(pickerButton('新建并添加'));
      await tester.tap(pickerButton('新建并添加'));
      await settleContent(tester);
      expect(find.textContaining('已新建“完整保存”并添加歌曲'), findsOneWidget);
      final parents = (await tester.runAsync(
        () => db.select(db.playlistRecords).get(),
      ))!;
      expect(parents.length, 1);
      final entries = (await tester.runAsync(
        () => services.collection.getPlaylistEntries(parents.single.playlistId),
      ))!;
      expect(entries.single.track, track.ref);
      expect(entries.single.position, 0);
      expect(
        (await tester.runAsync(() => services.library.getTrack(track.ref)))!
            .localPath,
        track.localPath,
      );
      expect(graph.playlists.entryFailure, isNull);
      expect(engine.calls, isEmpty);
      await tester.tap(pickerButton('完成'));
      await settleContent(tester);
      graph.libraryController.selectCategory(LibraryCategory.playlists);
      await settleContent(tester);
      expect(find.text('完整保存'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await closeGraph(tester, graph);
    },
  );
}
