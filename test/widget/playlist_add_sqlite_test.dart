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
import '../support/playlist_content_probe.dart';

void main() {
  setUpAll(loadDesignAssets);
  testWidgets(
    'Library picker persists independent duplicate entries in real SQLite without copying tracks',
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
      for (var i = 0; i < 2; i++) {
        final row = find.byKey(ValueKey(track.ref));
        await tester.ensureVisible(row);
        await tester.longPress(row);
        await tester.pumpAndSettle();
        await tester.tap(find.text('添加到歌单'));
        await settleContent(tester);
        await tester.tap(choiceButton('sql'));
        await settleContent(tester);
        expect(find.textContaining('已添加到'), findsOneWidget);
        await tester.tap(pickerButton('完成'));
        await settleContent(tester);
      }
      final entries = (await tester.runAsync(
        () => services.collection.getPlaylistEntries('sql'),
      ))!;
      expect(entries.length, 2);
      expect(entries.map((e) => e.id).toSet().length, 2);
      expect(entries.every((e) => e.track == track.ref), isTrue);
      expect(
        (await tester.runAsync(() => services.library.getTrack(track.ref)))!
            .localPath,
        track.localPath,
      );
      expect(engine.calls, isEmpty);
      expect(graph.playlistAdds.retainedSessionCount, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await closeGraph(tester, graph);
    },
  );
}
