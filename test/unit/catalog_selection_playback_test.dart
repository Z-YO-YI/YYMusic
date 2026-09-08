import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_state.dart';

import '../support/catalog_detail_probe.dart';
import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';
import '../support/playlist_content_probe.dart';

void main() {
  final tracks = List.generate(4, (i) => detailTrack('$i'));
  late FakeAudioEngine engine;
  late FakeCollectionRepository collection;
  late FakeLibraryRepository library;
  late PlaybackController player;
  int Function(int) random = (_) => 0;
  setUp(() async {
    random = (_) => 0;
    engine = FakeAudioEngine();
    collection = FakeCollectionRepository();
    library = FakeLibraryRepository(tracks: tracks);
    player = PlaybackController(
      engine,
      collection: collection,
      library: library,
      sourceResolver: FakePlaybackSourceResolver(),
      clock: () => contentEpoch,
      randomIndex: (n) => random(n),
    );
    await player.initialize();
  });
  tearDown(() async {
    await player.close();
    await engine.dispose();
    await collection.dispose();
    await library.dispose();
  });
  test('one durable replacement preserves 205 repeated entries and starts sequentially', () async {
    await player.playCatalogSelection([tracks.last.ref], shuffle: true);
    collection.queueWrites.clear();
    final input = List.generate(205, (i) => tracks[i % 4].ref);
    final expected = List.of(input);
    final publishedModes = <bool>[];
    player.addListener(() {
      if (player.state.queue.entries.length == 205) {
        publishedModes.add(player.state.shuffleEnabled);
      }
    });
    final result = player.playCatalogSelection(input, shuffle: false);
    input.clear();
    expect(await result, isTrue);
    final queue = player.state.queue;
    expect(queue.entries.map((e) => e.track), expected);
    expect(queue.entries.map((e) => e.id).toSet().length, 205);
    expect(queue.entries.map((e) => e.position), List.generate(205, (i) => i));
    expect(queue.entries.every((e) => e.addedAt == contentEpoch), isTrue);
    expect(collection.queueWrites.length, 1);
    expect(publishedModes, everyElement(isFalse));
    expect(player.state.currentTrack!.ref, tracks.first.ref);
    await player.skipNext();
    expect(player.state.currentTrack!.ref, tracks[1].ref);
    expect(player.state.phase, PlaybackPhase.playing);
  });
  test('shuffle picks a random first and traverses each distinct entry exactly once', () async {
    player.setRepeatMode(RepeatMode.off);
    final publishedModes = <bool>[];
    player.addListener(() {
      if (player.state.queue.entries.isNotEmpty) {
        publishedModes.add(player.state.shuffleEnabled);
      }
    });
    await player.playCatalogSelection(tracks.map((t) => t.ref), shuffle: true);
    expect(collection.queueWrites.length, 1);
    expect(
      player.state.queue.entries.map((e) => e.track),
      tracks.map((t) => t.ref),
    );
    final order = [player.state.currentTrack!.ref];
    for (var i = 0; i < 3; i++) {
      await player.skipNext();
      order.add(player.state.currentTrack!.ref);
    }
    expect(order, [tracks[1].ref, tracks[2].ref, tracks[3].ref, tracks[0].ref]);
    expect(publishedModes, everyElement(isTrue));
    final count = engine.calls.length;
    await player.skipNext();
    expect(engine.calls.length, count);
  });
  test(
    'empty and revoked selections leave active queue and audio untouched',
    () async {
      await player.playCatalogSelection([tracks.first.ref], shuffle: false);
      final queue = player.state.queue;
      engine.calls.clear();
      collection.queueWrites.clear();
      expect(await player.playCatalogSelection([], shuffle: true), isFalse);
      expect(
        await player.playCatalogSelection(
          [tracks.last.ref],
          shuffle: true,
          canPlay: () => false,
        ),
        isFalse,
      );
      expect(player.state.queue, same(queue));
      expect(collection.queueWrites, isEmpty);
      expect(engine.calls, isEmpty);
    },
  );
  test('invalid random output fails before stop or persistence', () async {
    await player.playCatalogSelection([tracks.first.ref], shuffle: false);
    final queue = player.state.queue;
    engine.calls.clear();
    collection.queueWrites.clear();
    random = (n) => n;
    await expectLater(
      player.playCatalogSelection(tracks.map((t) => t.ref), shuffle: true),
      throwsA(isA<DomainFailure>()),
    );
    expect(player.state.queue, same(queue));
    expect(player.state.shuffleEnabled, isFalse);
    expect(engine.calls, isEmpty);
    expect(collection.queueWrites, isEmpty);
  });
  test('failed persistence retains old queue/mode and never starts replacement audio', () async {
    await player.playCatalogSelection([tracks.first.ref], shuffle: true);
    final queue = player.state.queue;
    engine.calls.clear();
    collection.beforeQueueWrite = (_) async =>
        throw StateError('private-marker');
    await expectLater(
      player.playCatalogSelection([tracks.last.ref], shuffle: false),
      throwsA(
        isA<DomainFailure>().having(
          (e) => e.toString(),
          'safe',
          isNot(contains('private-marker')),
        ),
      ),
    );
    expect(player.state.queue, same(queue));
    expect((await collection.loadQueue()).currentEntryId, queue.currentEntryId);
    expect(player.state.shuffleEnabled, isTrue);
    expect(engine.calls, ['stop']);
  });
  for (final boundary in ['persist', 'load']) {
    test(
      'revocation during $boundary drains accepted work without starting audio',
      () async {
        final gate = Completer<void>();
        addTearDown(() {
          if (!gate.isCompleted) gate.complete();
        });
        if (boundary == 'persist') {
          collection.beforeQueueWrite = (_) => gate.future;
        }
        if (boundary == 'load') engine.loadGate = gate.future;
        var active = true;
        final work = player.playCatalogSelection(
          tracks.map((t) => t.ref),
          shuffle: true,
          canPlay: () => active,
        );
        await contentTick();
        if (boundary == 'load') expect(engine.calls, ['load']);
        active = false;
        gate.complete();
        expect(await work, isFalse);
        expect((await collection.loadQueue()).entries.length, 4);
        expect(engine.calls, isNot(contains('play')));
        if (boundary == 'load') expect(engine.loadedSource, isNull);
      },
    );
  }
  test('queued selection is frozen and cancelled independently of prior accepted command', () async {
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    engine.loadGate = gate.future;
    final first = player.playCatalogSelection([
      tracks.first.ref,
    ], shuffle: false);
    await contentTick();
    var active = true;
    final second = player.playCatalogSelection(
      [tracks.last.ref],
      shuffle: true,
      canPlay: () => active,
    );
    active = false;
    gate.complete();
    expect(await first, isTrue);
    expect(await second, isFalse);
    expect(collection.queueWrites.length, 1);
    expect(player.state.currentTrack!.ref, tracks.first.ref);
  });
}
