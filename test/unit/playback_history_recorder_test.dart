import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/playback/playback_history_recorder.dart';

import '../support/catalog_detail_probe.dart';
import '../support/fake_domain_repositories.dart';
import '../support/playback_history_probe.dart';
import '../support/playlist_content_probe.dart';

void confirm(PlaybackHistoryRecorder recorder, String id) {
  recorder.begin(detailTrack(id).ref);
  recorder.activate();
  recorder.observe(historyState(0));
  recorder.observe(historyState(100));
}

void main() {
  test('no collection, idle construction and closed recorder have no I/O or failure', () async {
    final h = PlaybackHistoryRecorder();
    confirm(h, 'a');
    expect(h.busy, isFalse);
    expect(h.failure, isNull);
    await h.close();
    confirm(h, 'b');
    expect(h.busy, isFalse);
  });

  test('25 confirmed tracks at one timestamp retain 20 with strictly ordered starts and full refs', () async {
    final repository = FakeCollectionRepository();
    var id = 0;
    final h = PlaybackHistoryRecorder(
      collection: repository,
      clock: () => contentEpoch,
      idFactory: () => 'h-${id++}',
    );
    for (var i = 0; i < 25; i++) {
      confirm(h, '$i');
    }
    await waitHistory(h);
    final saved = await repository.watchHistory().first;
    expect(saved.length, 20);
    expect(saved.map((e) => e.track.trackId), [
      for (var i = 24; i >= 5; i--) '$i',
    ]);
    expect(
      saved.first.startedAt.difference(saved.last.startedAt).inMilliseconds,
      19,
    );
    await h.close();
    await repository.dispose();
  });

  test('recreated recorder seeds ordering from persisted history after clock rollback', () async {
    final repository = FakeCollectionRepository();
    final first = PlaybackHistoryRecorder(
      collection: repository,
      clock: () => contentEpoch,
      idFactory: () => 'first',
    );
    confirm(first, 'a');
    await first.close();
    final second = PlaybackHistoryRecorder(
      collection: repository,
      clock: () => contentEpoch.subtract(const Duration(days: 5)),
      idFactory: () => 'second',
    );
    confirm(second, 'b');
    await second.close();
    final saved = await repository.watchHistory().first;
    expect(saved.first.track.trackId, 'b');
    expect(
      saved.first.startedAt,
      contentEpoch.add(const Duration(milliseconds: 1)),
    );
    await repository.dispose();
  });

  for (final callback in ['clock', 'id']) {
    test(
      '$callback reentrant close drains the already registered write',
      () async {
        final repository = FakeCollectionRepository();
        late PlaybackHistoryRecorder h;
        Future<void>? closing;
        h = PlaybackHistoryRecorder(
          collection: repository,
          clock: () {
            if (callback == 'clock') closing = h.close();
            return contentEpoch;
          },
          idFactory: () {
            if (callback == 'id') closing = h.close();
            return 'record';
          },
        );
        confirm(h, 'a');
        await closing;
        expect(
          (await repository.watchHistory().first).single.track.trackId,
          'a',
        );
        expect(h.busy, isFalse);
        await h.close();
        await repository.dispose();
      },
    );
  }

  for (final callback in ['clock', 'id']) {
    test(
      '$callback failure is safe, cannot pretend to save, and always drains',
      () async {
        final repository = FakeCollectionRepository();
        final h = PlaybackHistoryRecorder(
          collection: repository,
          clock: () {
            if (callback == 'clock') throw StateError('private-marker');
            return contentEpoch;
          },
          idFactory: () {
            if (callback == 'id') throw StateError('private-marker');
            return 'record';
          },
        );
        confirm(h, 'a');
        await waitHistory(h);
        expect(h.failure.toString(), isNot(contains('private-marker')));
        expect(h.failure, isNotNull);
        expect(h.canRetry, isFalse);
        expect(await repository.watchHistory().first, isEmpty);
        await h.close();
        await repository.dispose();
      },
    );
  }

  test('read error is visible and retry uses the frozen observed time and identity', () async {
    final repository = FakeCollectionRepository()
      ..historyReader = () => Stream.error(StateError('private-marker'));
    var ids = 0;
    final h = PlaybackHistoryRecorder(
      collection: repository,
      clock: () => contentEpoch,
      idFactory: () => 'h-${ids++}',
    );
    confirm(h, 'a');
    await waitHistory(h);
    expect(h.canRetry, isTrue);
    repository.historyReader = null;
    await h.retry(h.failure!);
    final saved = (await repository.watchHistory().first).single;
    expect(saved.id, 'h-0');
    expect(ids, 1);
    expect(saved.startedAt, contentEpoch);
    await h.close();
    await repository.dispose();
  });

  test('failure notification may close reentrantly without abandoning a pending result', () async {
    final repository = FakeCollectionRepository()
      ..onHistoryRecord = (_) async => throw StateError('private-marker');
    final h = PlaybackHistoryRecorder(collection: repository);
    Future<void>? closing;
    h.addListener(() {
      if (h.failure != null) closing ??= h.close();
    });
    confirm(h, 'a');
    await contentTick();
    await closing;
    expect(h.busy, isFalse);
    expect(h.failure, isNotNull);
    await repository.dispose();
  });
}
