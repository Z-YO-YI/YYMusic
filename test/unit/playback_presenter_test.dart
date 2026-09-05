import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_player_data.dart';
import 'package:yymusic/playback/audio_engine_state.dart';

import '../support/playback_graph_fixture.dart';

void main() {
  late PlaybackGraphFixture fixture;
  setUp(() => fixture = PlaybackGraphFixture());
  tearDown(() => fixture.graph.close());

  test(
    'empty state does not pretend playback and controller snapshots map live',
    () async {
      final presenter = fixture.graph.playbackPresenter;
      expect(presenter.data.title, '尚未选择音乐');
      expect(presenter.canControl, isFalse);
      await presenter.togglePlayback();
      expect(fixture.engine.calls, isEmpty);
      await fixture.queue();
      expect(presenter.canControl, isTrue);
      expect(presenter.data.title, '队列已就绪');
      await presenter.togglePlayback();
      expect(presenter.data.title, fixture.tracks.first.title);
      expect(presenter.data.playing, isTrue);
      fixture.engine.events.add(
        AudioEngineState(
          phase: AudioEnginePhase.playing,
          position: const Duration(minutes: 4),
          duration: const Duration(minutes: 3),
          volume: .4,
        ),
      );
      expect(presenter.data.position, const Duration(minutes: 3));
      expect(presenter.data.progress, 1);
      expect(presenter.data.volume, .4);
    },
  );

  test(
    'transport and modes forward to the existing shared controller',
    () async {
      final presenter = fixture.graph.playbackPresenter;
      await fixture.queue();
      await presenter.togglePlayback();
      await presenter.togglePlayback();
      expect(fixture.engine.calls, ['load', 'play', 'pause']);
      presenter.toggleShuffle();
      expect(fixture.graph.playback.state.shuffleEnabled, isTrue);
      presenter.toggleShuffle();
      for (final repeat in [
        YYRepeatState.all,
        YYRepeatState.one,
        YYRepeatState.off,
      ]) {
        presenter.cycleRepeat();
        expect(presenter.data.repeat, repeat);
      }
      await presenter.next();
      expect(presenter.entryId, 'b');
      await presenter.previous();
      expect(presenter.entryId, 'a');
    },
  );

  test(
    'pending load drops duplicate UI commands and safe error can retry',
    () async {
      await fixture.queue();
      final presenter = fixture.graph.playbackPresenter;
      final gate = Completer<void>();
      fixture.engine.loadGate = gate.future;
      fixture.engine.loadError = StateError('private-source-marker');
      final play = presenter.togglePlayback();
      expect(presenter.busy, isTrue);
      await presenter.togglePlayback();
      gate.complete();
      await play;
      expect(fixture.engine.calls, ['load']);
      expect(presenter.busy, isFalse);
      expect(presenter.errorMessage, isNotNull);
      expect(presenter.errorMessage, isNot(contains('private-source-marker')));
      fixture.engine.loadError = null;
      await presenter.togglePlayback();
      expect(presenter.errorMessage, isNull);
      expect(presenter.data.playing, isTrue);
    },
  );

  test(
    'seek is bound to entry at execution, and invalid UI fractions do nothing',
    () async {
      await fixture.queue();
      final presenter = fixture.graph.playbackPresenter;
      await presenter.togglePlayback();
      await presenter.seek(.5, expectedEntryId: 'a');
      expect(fixture.engine.calls.last, 'seek:90000');
      final next = fixture.graph.playback.skipNext();
      final staleSeek = presenter.seek(.7, expectedEntryId: 'a');
      await next;
      await staleSeek;
      expect(presenter.entryId, 'b');
      expect(fixture.engine.calls.where((call) => call.startsWith('seek:')), [
        'seek:90000',
      ]);
      final before = fixture.engine.calls.length;
      for (final value in [double.nan, double.infinity, -.1, 1.1]) {
        await presenter.seek(value, expectedEntryId: 'b');
        await presenter.setVolume(value);
      }
      expect(fixture.engine.calls.length, before);
      await presenter.setVolume(.25);
      expect(fixture.engine.volume, .25);
    },
  );

  test(
    'presenter shutdown removes notifications without owning engine lifetime',
    () async {
      await fixture.queue();
      final presenter = fixture.graph.playbackPresenter;
      var notifications = 0;
      presenter.addListener(() => notifications++);
      final gate = Completer<void>();
      fixture.engine.loadGate = gate.future;
      final pending = presenter.togglePlayback();
      presenter.dispose();
      final before = notifications;
      gate.complete();
      await pending;
      expect(notifications, before);
      expect(fixture.engine.disposalCount, 0);
      await presenter.togglePlayback();
      expect(notifications, before);
    },
  );
}
