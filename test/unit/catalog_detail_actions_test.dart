import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/music_source.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_state.dart';

import '../support/catalog_detail_graph_fixture.dart';
import '../support/catalog_detail_probe.dart';

Future<void> drainDetail() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('detail uses one player, public name and queue identity with no offscreen/unavailable play', () async {
    final f = CatalogDetailGraphFixture();
    addTearDown(f.close);
    await f.initialize();
    final c = f.graph.catalogDetails.open(AlbumDetailTarget(f.album.ref));
    await c.start();
    expect(c.sourceLabel, '我的本地音乐');
    final a = f.repository.trackData.first;
    final b = f.repository.trackData[1];
    expect(c.canPlay(f.repository.trackData[2].ref), isFalse);
    expect(c.canPlay(detailTrack('not-in-page').ref), isFalse);
    await c.play(a.ref);
    await c.play(b.ref);
    await c.play(a.ref);
    expect(f.graph.playback.state.queue.entries.length, 2);
    expect(f.engine.calls.where((call) => call == 'play').length, 3);
    c.setActive(false);
    expect(c.canPlay(a.ref), isFalse);
    await c.play(b.ref);
    expect(f.engine.calls.where((call) => call == 'play').length, 3);
    c.setActive(true);
    expect(c.canPlay(a.ref), isTrue);
  });

  for (final revoke in ['leave', 'refresh', 'close']) {
    test(
      '$revoke cancels loaded-but-not-playing intent and drains action',
      () async {
        final f = CatalogDetailGraphFixture();
        addTearDown(f.close);
        await f.initialize();
        final c = f.graph.catalogDetails.open(AlbumDetailTarget(f.album.ref));
        await c.start();
        final gate = Completer<void>();
        f.engine.loadGate = gate.future;
        final play = c.play(f.repository.trackData.first.ref);
        await drainDetail();
        expect(f.engine.calls, contains('load'));
        expect(c.busy, isTrue);
        Future<void>? closed;
        if (revoke == 'leave') c.setActive(false);
        if (revoke == 'refresh') await c.refresh();
        if (revoke == 'close') closed = c.close();
        gate.complete();
        await play;
        await closed;
        expect(f.engine.calls, isNot(contains('play')));
        expect(f.engine.calls, contains('stop'));
        expect(c.busy, isFalse);
      },
    );
  }

  test('source read failures and late names never hide or overwrite current detail data', () async {
    final f = CatalogDetailGraphFixture();
    addTearDown(f.close);
    await f.initialize();
    final gate = Completer<MusicSourceConfig?>();
    f.sources.sourceReader = (_) => gate.future;
    final c = f.graph.catalogDetails.open(AlbumDetailTarget(f.album.ref));
    final first = c.start();
    await drainDetail();
    expect(c.tracks.phase, LoadPhase.data);
    expect(c.sourceLabel, '来源读取中');
    f.sources.sourceReader = (_) async => throw StateError('private-marker');
    await c.refresh();
    expect(c.sourceLabel, '来源未配置');
    gate.complete(
      MusicSourceConfig(
        id: 'source-a',
        name: '旧来源名称',
        type: MusicSourceType.local,
        authType: MusicSourceAuthType.system,
      ),
    );
    await first;
    expect(c.sourceLabel, '来源未配置');
    expect(c.summary.phase, LoadPhase.data);
  });

  test('root close waits for independent source lookup without leaking stale names', () async {
    final f = CatalogDetailGraphFixture();
    await f.initialize();
    final gate = Completer<MusicSourceConfig?>();
    f.sources.sourceReader = (_) => gate.future;
    final c = f.graph.catalogDetails.open(AlbumDetailTarget(f.album.ref));
    final load = c.start();
    await drainDetail();
    var completed = false;
    final close = f.graph.close().then((_) => completed = true);
    await drainDetail();
    expect(completed, isFalse);
    gate.complete(null);
    await load;
    await close;
    expect(f.engine.disposalCount, 1);
    await f.disposeFakes();
  });
}
