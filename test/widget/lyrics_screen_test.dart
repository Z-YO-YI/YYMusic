import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_lyrics_line.dart';
import 'package:yymusic/design_system/yy_lyrics_player_dock.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/lyrics.dart';
import 'package:yymusic/features/lyrics/common/lyrics_screen.dart';
import 'package:yymusic/features/lyrics/common/lyrics_viewport.dart';
import 'package:yymusic/features/lyrics/phone/phone_lyrics_layout.dart';
import 'package:yymusic/features/lyrics/tablet/tablet_lyrics_layout.dart';
import 'package:yymusic/features/lyrics/windows/windows_lyrics_layout.dart';
import 'package:yymusic/features/player/common/player_screen.dart';
import 'package:yymusic/features/player/common/shell_player.dart';

import '../support/design_harness.dart';
import '../support/lyrics_fixture.dart';
import '../support/native_lyrics_harness.dart';
import 'player_screen_test.dart' show playerSizes;

YYLyricsPlayerDock dock(WidgetTester tester) =>
    tester.widget<YYLyricsPlayerDock>(find.byType(YYLyricsPlayerDock));
LyricsScreen screen(WidgetTester tester) =>
    tester.widget<LyricsScreen>(find.byType(LyricsScreen));
LyricsViewport viewport(WidgetTester tester) =>
    tester.widget<LyricsViewport>(find.byType(LyricsViewport));

void main() {
  setUpAll(loadDesignAssets);
  for (final (platform, size) in playerSizes) {
    testWidgets(
      'native lyrics $platform $size at 130 percent uses root playback',
      (tester) async {
        final fixture = await mountLyrics(
          tester,
          platform: platform,
          size: size,
        );
        expect(find.byType(ShellPlayer), findsNothing);
        expect(
          find.byType(
            platform == YYPlatform.windows
                ? WindowsLyricsLayout
                : size.width < 600
                ? PhoneLyricsLayout
                : TabletLyricsLayout,
          ),
          findsOneWidget,
        );
        expect(screen(tester).controller, same(fixture.graph.lyricsController));
        expect(fixture.graph.lyricsController.activeIndex, 0);
        expect(fixture.repository.reads, hasLength(1));
        expect(dock(tester).data.playing, isTrue);
        expect(dock(tester).showFavorite, isFalse);
        await tester.tap(find.byKey(const ValueKey('lyrics-dock-pause')));
        await settleLyrics(tester);
        expect(fixture.engine.calls.last, 'pause');
        await tester.tap(find.byKey(const ValueKey('lyrics-dock-next')));
        await settleLyrics(tester);
        expect(fixture.graph.playbackPresenter.entryId, 'entry-1');
        expect(viewport(tester).document.track, lyricsTracks[1].ref);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'translation toggles without reread and root line seek applies offset',
    (tester) async {
      final fixture = await mountLyrics(
        tester,
        configure: (f) =>
            f.repository.documents[lyricsTracks.first.ref] = timedLyrics(
              lyricsTracks.first.ref,
              offset: const Duration(seconds: 3),
            ),
      );
      await tester.tap(find.byKey(const ValueKey('lyrics-translation')));
      await settleLyrics(tester);
      expect(viewport(tester).showTranslation, isFalse);
      expect(find.text('测试行 0'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('lyrics-translation')));
      await settleLyrics(tester);
      expect(find.text('测试行 0'), findsOneWidget);
      await tester.tap(find.text('Test line 0'));
      await settleLyrics(tester);
      expect(fixture.engine.calls.last, 'seek:13000');
      expect(fixture.repository.reads, hasLength(1));
    },
  );

  testWidgets('plain lyrics are readable and have no line seek action', (
    tester,
  ) async {
    final fixture = await mountLyrics(
      tester,
      configure: (f) =>
          f.repository.documents[lyricsTracks.first.ref] = LyricsDocument(
            track: lyricsTracks.first.ref,
            kind: LyricsKind.plain,
            language: 'en',
            lines: [LyricsLine(text: 'Plain test text')],
          ),
    );
    expect(viewport(tester).onSeek, isNull);
    expect(find.byKey(const ValueKey('lyrics-translation')), findsNothing);
    final calls = fixture.engine.calls.length;
    await tester.tap(find.text('Plain test text'));
    await settleLyrics(tester);
    expect(fixture.engine.calls, hasLength(calls));
    expect(
      tester.widget<YYLyricsLine>(find.byType(YYLyricsLine)).onPressed,
      isNull,
    );
  });

  testWidgets(
    'empty queue and missing lyrics are honest and retry can recover',
    (tester) async {
      final fixture = await mountLyrics(tester, empty: true);
      expect(find.text('尚未选择音乐'), findsNWidgets(3));
      expect(dock(tester).onTogglePlayback, isNull);
      expect(fixture.repository.reads, isEmpty);
      await tester.runAsync(() async {
        fixture.repository.documents.clear();
        await fixture.graph.queue.replace(
          lyricsEntries(),
          currentEntryId: 'entry-0',
        );
        await fixture.graph.playback.play();
      });
      await settleLyrics(tester);
      expect(find.text('暂无歌词'), findsOneWidget);
      fixture.repository.documents[lyricsTracks.first.ref] = timedLyrics(
        lyricsTracks.first.ref,
      );
      await tester.tap(find.text('重试'));
      await settleLyrics(tester);
      expect(find.byType(LyricsViewport), findsOneWidget);
    },
  );

  testWidgets(
    'loading error is sanitized and explicit retry preserves playback',
    (tester) async {
      final gate = Completer<LyricsDocument?>();
      final fixture = await mountLyrics(
        tester,
        configure: (f) => f.repository.onGet = (_) => gate.future,
      );
      expect(find.text('正在读取歌词'), findsOneWidget);
      gate.completeError(StateError('private-marker'));
      await settleLyrics(tester);
      expect(find.text('歌词读取失败'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      expect(dock(tester).data.playing, isTrue);
      fixture.repository.onGet = null;
      await tester.tap(find.text('重试'));
      await settleLyrics(tester);
      expect(find.byType(LyricsViewport), findsOneWidget);
      expect(fixture.repository.maximumInFlight, 1);
    },
  );

  for (final platform in [YYPlatform.android, YYPlatform.windows]) {
    testWidgets(
      'metadata long press opens lyrics and short press still opens player on $platform',
      (tester) async {
        final fixture = await mountLyrics(
          tester,
          platform: platform,
          size: platform == YYPlatform.windows
              ? const Size(500, 640)
              : const Size(390, 844),
          route: '/home',
        );
        final metadata = find.byKey(
          ValueKey(
            platform == YYPlatform.android
                ? 'mini-player-track'
                : 'desktop-player-track',
          ),
        );
        final calls = fixture.engine.calls.length;
        await tester.longPress(metadata);
        await settleLyrics(tester);
        expect(find.byType(LyricsScreen), findsOneWidget);
        expect(fixture.engine.calls, hasLength(calls));
        await tester.tap(find.byKey(const ValueKey('route-back')));
        await settleLyrics(tester);
        expect(fixture.graph.lyricsController.isActive, isFalse);
        await tester.tap(metadata);
        await settleLyrics(tester);
        expect(find.byType(PlayerScreen), findsOneWidget);
      },
    );
  }

  testWidgets(
    'ten player lyrics cycles reuse player and close to original home',
    (tester) async {
      final fixture = await mountLyrics(tester, route: '/home');
      tester.widget<ShellPlayer>(find.byType(ShellPlayer)).onOpen!();
      await settleLyrics(tester);
      final original = tester.state(find.byType(PlayerScreen));
      final calls = fixture.engine.calls.length;
      for (var i = 0; i < 10; i++) {
        final navigation = tester
            .widget<PlayerScreen>(find.byType(PlayerScreen))
            .navigation;
        navigation.openLyrics();
        navigation.openLyrics();
        await settleLyrics(tester);
        expect(find.byType(LyricsScreen, skipOffstage: false), findsOneWidget);
        expect(fixture.graph.lyricsController.isActive, isTrue);
        await tester.tap(find.byKey(const ValueKey('lyrics-dock-music')));
        await settleLyrics(tester);
        expect(tester.state(find.byType(PlayerScreen)), same(original));
        expect(find.byType(PlayerScreen, skipOffstage: false), findsOneWidget);
        expect(find.byType(LyricsScreen, skipOffstage: false), findsNothing);
      }
      await tester.tap(find.byKey(const ValueKey('route-back')));
      await settleLyrics(tester);
      expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
      expect(fixture.engine.calls, hasLength(calls));
    },
  );

  testWidgets(
    'home lyrics return to player replaces lyrics then back reaches home',
    (tester) async {
      await mountLyrics(tester, route: '/home');
      tester.widget<ShellPlayer>(find.byType(ShellPlayer)).onOpenLyrics!();
      await settleLyrics(tester);
      dock(tester).onReturnToPlayer!();
      await settleLyrics(tester);
      expect(find.byType(PlayerScreen), findsOneWidget);
      expect(find.byType(LyricsScreen, skipOffstage: false), findsNothing);
      await tester.tap(find.byKey(const ValueKey('route-back')));
      await settleLyrics(tester);
      expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
    },
  );

  testWidgets(
    'direct lyrics system back returns home and stops lyrics activity only',
    (tester) async {
      final fixture = await mountLyrics(tester);
      await tester.binding.handlePopRoute();
      await settleLyrics(tester);
      expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
      expect(fixture.graph.lyricsController.isActive, isFalse);
      expect(fixture.graph.playbackPresenter.data.playing, isTrue);
    },
  );

  testWidgets(
    'covered lyrics and late read are revoked, returning starts fresh read',
    (tester) async {
      final gate = Completer<LyricsDocument?>();
      final fixture = await mountLyrics(
        tester,
        configure: (f) => f.repository.onGet = (_) => gate.future,
      );
      screen(tester).navigation.openSystemPlaylist(SystemPlaylistType.queue);
      await settleLyrics(tester);
      expect(fixture.graph.lyricsController.isActive, isFalse);
      gate.complete(timedLyrics(lyricsTracks.first.ref));
      await settleLyrics(tester);
      expect(fixture.graph.lyricsController.state.phase, LoadPhase.idle);
      fixture.repository.onGet = null;
      await tester.binding.handlePopRoute();
      await settleLyrics(tester);
      expect(find.byType(LyricsViewport), findsOneWidget);
      expect(fixture.repository.reads, hasLength(2));
    },
  );

  testWidgets(
    'native dock progress previews once and cancels without seeking',
    (tester) async {
      final fixture = await mountLyrics(tester);
      final slider = find.byKey(const ValueKey('lyrics-dock-progress'));
      final rect = tester.getRect(slider);
      final before = fixture.engine.calls
          .where((e) => e.startsWith('seek:'))
          .length;
      final gesture = await tester.startGesture(
        rect.centerLeft + const Offset(8, 0),
      );
      await gesture.moveTo(rect.center);
      await tester.pump();
      expect(
        fixture.engine.calls.where((e) => e.startsWith('seek:')),
        hasLength(before),
      );
      await gesture.up();
      await settleLyrics(tester);
      expect(
        fixture.engine.calls.where((e) => e.startsWith('seek:')),
        hasLength(before + 1),
      );
      final position = fixture.graph.playback.state.position;
      final cancel = await tester.startGesture(rect.center);
      await cancel.moveTo(rect.centerRight - const Offset(8, 0));
      await tester.pump();
      await cancel.cancel();
      await settleLyrics(tester);
      expect(dock(tester).data.position, position);
      expect(
        fixture.engine.calls.where((e) => e.startsWith('seek:')),
        hasLength(before + 1),
      );
    },
  );

  for (final change in ['resize', 'hide', 'zero', 'dispose']) {
    testWidgets(
      'queued lyric and retained dock intents are revoked by $change',
      (tester) async {
        final fixture = await mountLyrics(tester);
        final oldDock = dock(tester);
        final seek = viewport(tester).onSeek!;
        final before = fixture.engine.calls
            .where((e) => e.startsWith('seek:'))
            .length;
        final gate = Completer<void>();
        fixture.engine.pauseGate = gate.future;
        unawaited(fixture.graph.playback.pause());
        await settleLyrics(tester);
        seek(1);
        if (change == 'hide') {
          screen(tester).navigation
              .openSystemPlaylist(SystemPlaylistType.queue);
        }
        if (change == 'resize') tester.view.physicalSize = const Size(844, 390);
        if (change == 'zero') tester.view.physicalSize = Size.zero;
        if (change == 'dispose') {
          await tester.pumpWidget(const SizedBox.shrink());
        }
        await tester.pump();
        oldDock.onSeekCommit!(.8);
        gate.complete();
        await settleLyrics(tester);
        expect(
          fixture.engine.calls.where((e) => e.startsWith('seek:')),
          hasLength(before),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Windows L opens lyrics without playback and Escape restores home',
    (tester) async {
      final fixture = await mountLyrics(
        tester,
        platform: YYPlatform.windows,
        size: const Size(1024, 720),
        route: '/home',
      );
      final before = fixture.engine.calls.length;
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await settleLyrics(tester);
      expect(find.byType(LyricsScreen), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleLyrics(tester);
      expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
      expect(fixture.engine.calls, hasLength(before));
    },
  );

  testWidgets(
    'Windows letter L never steals editable search input and Ctrl L remains library',
    (tester) async {
      await mountLyrics(
        tester,
        platform: YYPlatform.windows,
        size: const Size(1024, 720),
        route: '/search',
      );
      await tester.tap(find.byType(EditableText));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await settleLyrics(tester);
      expect(find.byType(LyricsScreen), findsNothing);
      await tester.enterText(find.byType(EditableText), 'local');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settleLyrics(tester);
      expect(find.byKey(const ValueKey('screen-library')), findsOneWidget);
    },
  );

  testWidgets('lyrics dock restores player below intermediate queue route', (
    tester,
  ) async {
    await mountLyrics(tester, route: '/home');
    tester.widget<ShellPlayer>(find.byType(ShellPlayer)).onOpen!();
    await settleLyrics(tester);
    final player = tester.state(find.byType(PlayerScreen));
    final navigation = tester
        .widget<PlayerScreen>(find.byType(PlayerScreen))
        .navigation;
    navigation.openSystemPlaylist(SystemPlaylistType.queue);
    await settleLyrics(tester);
    navigation.openLyrics();
    await settleLyrics(tester);
    dock(tester).onReturnToPlayer!();
    await settleLyrics(tester);
    expect(tester.state(find.byType(PlayerScreen)), same(player));
    navigation.back();
    await settleLyrics(tester);
    expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
  });
}
