import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/audio_engine.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/audio_sequence.dart';
import 'package:yymusic/playback/playable_source.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';
import 'package:yymusic/playback/playback_source_resolver.dart';
import 'package:yymusic/playback/playback_state.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';
import '../support/playback_history_probe.dart' show waitHistory;

void main() {
  final tracks = List.generate(
    3,
    (i) => Track(
      id: 'track-$i',
      sourceId: 'fixture',
      sourceType: MusicSourceType.local,
      title: 'Track $i',
      artists: const ['Fixture'],
      duration: const Duration(minutes: 3),
      localPath: '/fixture/$i.wav',
    ),
  );
  late NativeEngine engine;
  late FakeCollectionRepository collection;
  late FakeLibraryRepository library;
  late PlaybackController root;
  late FakeMediaSessionGateway media;
  late GatedResolver resolver;
  setUp(() async {
    engine = NativeEngine();
    collection = FakeCollectionRepository();
    library = FakeLibraryRepository(tracks: tracks);
    media = FakeMediaSessionGateway();
    resolver = GatedResolver();
    root = PlaybackController(
      engine,
      library: library,
      collection: collection,
      sourceResolver: resolver,
      mediaSession: media,
      randomIndex: (upper) => upper - 1,
    );
    await root.initialize();
    await root.replaceQueue([
      for (var i = 0; i < 3; i++)
        QueueEntry(
          id: 'q$i',
          track: tracks[i].ref,
          position: i,
          addedAt: DateTime.utc(2026),
        ),
    ], currentEntryId: 'q0');
    collection.queueWrites.clear();
  });
  tearDown(() async {
    await root.close();
    await engine.dispose();
    await collection.dispose();
    await library.dispose();
    await media.dispose();
  });

  test(
    'pending completion preserves genuine progress evidence for history',
    () async {
      await root.playNativeSequence('q0');
      final gate = Completer<void>();
      collection.beforeQueueWrite = (_) => gate.future;
      engine.tick(1, 0);
      engine.tick(1, 200);
      engine.complete();
      gate.complete();
      await flush();
      await waitHistory(root.history);
      expect(
        (await collection.watchHistory().first).any(
          (entry) => entry.track == tracks[1].ref,
        ),
        isTrue,
      );
    },
  );

  test(
    'adopted metadata never publishes another entry clock or a synthetic zero',
    () async {
      await root.playNativeSequence('q0');
      final observed = <PlaybackState>[];
      root.addListener(() {
        observed.add(root.state);
      });
      engine.tick(1, 250);
      await flush();
      final adopted = observed.where(
        (state) => state.queue.currentEntryId == 'q1',
      );
      expect(adopted, isNotEmpty);
      expect(
        adopted.every(
          (state) =>
              state.currentTrack!.ref == tracks[1].ref &&
              state.position == const Duration(milliseconds: 250),
        ),
        isTrue,
      );
    },
  );

  test(
    'rejected native transition during load cannot later start playback',
    () async {
      engine.loadGate = Completer<void>();
      final playing = root.playNativeSequence('q0');
      final rejected = expectLater(playing, throwsA(isA<DomainFailure>()));
      await flush();
      engine.tick(1, 10);
      engine.loadGate!.complete();
      await rejected;
      await flush();
      expect(engine.calls, isNot(contains('play')));
      expect(engine.calls.last, 'stop');
      expect(root.state.queue.currentEntryId, 'q0');
    },
  );

  test(
    'real SQLite stores native transition and a new root restores without play',
    () async {
      final services = await DatabaseAppDataServices.open(
        AppDatabase(NativeDatabase.memory()),
      );
      final native = NativeEngine();
      final first = PlaybackController(
        native,
        library: library,
        collection: services.collection,
        sourceResolver: FakePlaybackSourceResolver(),
      );
      await services.collection.saveQueue(root.state.queue);
      await first.initialize();
      await first.playNativeSequence('q0');
      native.tick(1, 0);
      final deadline = DateTime.now().add(const Duration(seconds: 3));
      while (first.state.queue.currentEntryId != 'q1' &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(first.state.queue.currentEntryId, 'q1');
      expect((await services.collection.loadQueue()).currentEntryId, 'q1');
      await first.close();
      await native.dispose();
      final restoredEngine = NativeEngine();
      final restored = PlaybackController(
        restoredEngine,
        library: library,
        collection: services.collection,
        sourceResolver: FakePlaybackSourceResolver(),
      );
      await restored.initialize();
      expect(restored.state.queue.currentEntryId, 'q1');
      expect(restoredEngine.calls, isEmpty);
      await restored.close();
      await restoredEngine.dispose();
      await services.dispose();
    },
  );

  test('unavailable tail stays in queue and uses existing skip diagnostics at completion', () async {
    await library.upsertTracks([
      Track(
        id: tracks[1].id,
        sourceId: 'fixture',
        sourceType: MusicSourceType.local,
        title: 'Missing',
        artists: const ['Fixture'],
        duration: tracks[1].duration,
        localPath: '/missing.wav',
        availability: TrackAvailability.localMissing,
      ),
    ]);
    await root.playNativeSequence('q0');
    expect(engine.calls.first, 'sequence:1');
    engine.complete();
    await flush();
    expect(root.state.queue.currentEntryId, 'q2');
    expect(root.state.queue.entries, hasLength(3));
    expect(root.queuePlaybackFailures.single.entryId, 'q1');
  });

  test(
    'shuffle initial order is owned by root and a later change truncates',
    () async {
      root.setShuffleEnabled(true);
      await root.playNativeSequence('q0');
      final next = engine.sequence!.cursors[1].entryId;
      engine.tick(1, 0);
      await flush();
      expect(root.state.queue.currentEntryId, next);
      root.setShuffleEnabled(false);
      await flush();
      expect(engine.calls.last, 'retain:1');
    },
  );

  test(
    'continuation change during tail resolution reduces preload to current',
    () async {
      resolver.gate = Completer<void>();
      resolver.gateTrack = 'track-1';
      final playing = root.playNativeSequence('q0');
      await flush();
      root.setContinueAfterTrack(false);
      resolver.gate!.complete();
      await playing;
      expect(engine.calls, ['sequence:1', 'play']);
    },
  );

  test(
    'revoked play intent after tail I/O causes no native load or queue write',
    () async {
      resolver.gate = Completer<void>();
      resolver.gateTrack = 'track-1';
      var allowed = true;
      final playing = root.playNativeSequence('q0', canPlay: () => allowed);
      await flush();
      allowed = false;
      resolver.gate!.complete();
      await playing;
      expect(engine.calls, isEmpty);
      expect(collection.queueWrites, isEmpty);
    },
  );

  test(
    'already observed transition can commit before subsequent off boundary',
    () async {
      await root.playNativeSequence('q0');
      final gate = Completer<void>();
      collection.beforeQueueWrite = (_) => gate.future;
      engine.tick(1, 0);
      await flush();
      expect(root.canSleepAtCurrentEntryEnd, isFalse);
      root.setContinueAfterTrack(false);
      gate.complete();
      await flush();
      expect(root.state.queue.currentEntryId, 'q1');
      expect(engine.calls.last, 'retain:1');
    },
  );

  test(
    'out-of-order native jump stops without adopting skipped entry identities',
    () async {
      await root.playNativeSequence('q0');
      engine.tick(2, 10);
      await flush();
      expect(root.state.queue.currentEntryId, 'q0');
      expect(root.state.phase, PlaybackPhase.error);
      expect(engine.calls.last, 'stop');
    },
  );

  test('boundary rejection stops the active native sequence safely', () async {
    await root.playNativeSequence('q0');
    engine.retainResult = false;
    root.setContinueAfterTrack(false);
    await flush();
    expect(root.state.phase, PlaybackPhase.error);
    expect(engine.calls.last, 'stop');
  });

  test(
    'close during native load rejects playback after accepted load drains',
    () async {
      engine.loadGate = Completer<void>();
      final playing = root.playNativeSequence('q0');
      final rejected = expectLater(playing, throwsA(isA<DomainFailure>()));
      await flush();
      final closing = root.close();
      engine.loadGate!.complete();
      await rejected;
      await closing;
      expect(engine.calls, isNot(contains('play')));
    },
  );

  test(
    'one native load advances root metadata, persisted entry and history',
    () async {
      await root.playNativeSequence('q0');
      expect(engine.calls, ['sequence:3', 'play']);
      engine.tick(0, 100);
      await waitHistory(root.history);
      engine.tick(1, 0);
      await flush();
      expect(root.state.queue.currentEntryId, 'q1');
      expect(root.state.currentTrack!.ref, tracks[1].ref);
      expect((await collection.loadQueue()).currentEntryId, 'q1');
      engine.tick(1, 200);
      await waitHistory(root.history);
      expect(
        (await collection.watchHistory().first)
            .map((entry) => entry.track)
            .toSet(),
        {tracks[0].ref, tracks[1].ref},
      );
      expect(media.metadata.last, tracks[1].ref);
      expect(engine.calls, ['sequence:3', 'play']);
    },
  );

  test(
    'database delay holds old metadata then applies latest native clock',
    () async {
      await root.playNativeSequence('q0');
      final gate = Completer<void>();
      collection.beforeQueueWrite = (_) => gate.future;
      engine.tick(1, 0);
      await flush();
      engine.tick(1, 250);
      expect(root.state.queue.currentEntryId, 'q0');
      expect(root.state.currentTrack!.ref, tracks[0].ref);
      gate.complete();
      await flush();
      expect(root.state.queue.currentEntryId, 'q1');
      expect(root.state.position, const Duration(milliseconds: 250));
    },
  );

  test(
    'multiple observed transitions persist in order while storage waits',
    () async {
      await root.playNativeSequence('q0');
      final gate = Completer<void>();
      collection.beforeQueueWrite = (_) => gate.future;
      engine.tick(1, 0);
      engine.tick(2, 300);
      await flush();
      gate.complete();
      await flush();
      expect(collection.queueWrites.map((q) => q.currentEntryId), ['q1', 'q2']);
      expect(root.state.currentTrack!.ref, tracks[2].ref);
      expect(root.state.position, const Duration(milliseconds: 300));
    },
  );

  test(
    'duplicate TrackRef occurrences still update distinct queue entry IDs',
    () async {
      await root.replaceQueue([
        for (var i = 0; i < 2; i++)
          QueueEntry(
            id: 'copy$i',
            track: tracks[0].ref,
            position: i,
            addedAt: DateTime.utc(2026),
          ),
      ], currentEntryId: 'copy0');
      await root.playNativeSequence('copy0');
      engine.tick(1, 20);
      await flush();
      expect(root.state.queue.currentEntryId, 'copy1');
      expect(root.state.currentTrack!.ref, tracks[0].ref);
      expect(
        engine.calls.where((c) => c.startsWith('sequence:')),
        hasLength(1),
      );
    },
  );

  test(
    'turning continuation off retains current without new play or reload',
    () async {
      await root.playNativeSequence('q0');
      root.setContinueAfterTrack(false);
      await flush();
      expect(engine.calls, ['sequence:3', 'play', 'retain:0']);
      engine.complete();
      await flush();
      expect(root.state.queue.currentEntryId, 'q0');
      expect(root.state.phase, PlaybackPhase.completed);
    },
  );

  test('off before initial request loads only the selected track', () async {
    root.setContinueAfterTrack(false);
    await root.playNativeSequence('q1');
    expect(engine.calls, ['sequence:1', 'play']);
    expect(root.state.queue.currentEntryId, 'q1');
  });

  test('policy change while native load waits truncates before play', () async {
    engine.loadGate = Completer<void>();
    final loading = root.playNativeSequence('q0');
    await flush();
    root.setContinueAfterTrack(false);
    engine.loadGate!.complete();
    await loading;
    await flush();
    expect(
      engine.calls.indexOf('retain:0'),
      lessThan(engine.calls.indexOf('play')),
    );
  });

  test('entry-end sleep truncates and consumes without advancing', () async {
    await root.playNativeSequence('q0');
    expect(root.setSleepAtCurrentEntryEnd(), isTrue);
    await flush();
    expect(engine.calls.last, 'retain:0');
    engine.complete();
    await flush();
    expect(root.sleepTimer.phase, PlaybackSleepPhase.expired);
    expect(root.state.queue.currentEntryId, 'q0');
  });

  test('repeat one truncates and uses the shared seek/replay path', () async {
    await root.playNativeSequence('q0');
    root.setRepeatMode(RepeatMode.one);
    await flush();
    engine.complete();
    await flush();
    expect(root.state.queue.currentEntryId, 'q0');
    expect(engine.calls, containsAllInOrder(['retain:0', 'seek', 'play']));
  });

  test('queue edit retains current before writing changed entries', () async {
    await root.playNativeSequence('q0');
    collection.beforeQueueWrite = (_) async {
      expect(engine.calls.last, 'retain:0');
    };
    await root.removeQueueEntry('q2');
    expect(root.state.queue.entries.map((e) => e.id), ['q0', 'q1']);
    expect(engine.calls, ['sequence:3', 'play', 'retain:0']);
  });

  test('persistence failure stops native audio and does not publish wrong metadata', () async {
    await root.playNativeSequence('q0');
    collection.beforeQueueWrite = (_) async {
      throw StateError('private-sql');
    };
    engine.tick(1, 20);
    await flush();
    expect(root.state.queue.currentEntryId, 'q0');
    expect(root.state.currentTrack!.ref, tracks[0].ref);
    expect(root.state.phase, PlaybackPhase.error);
    expect(
      root.state.failure!.diagnosticId,
      'playback.native-sequence-transition',
    );
    expect(engine.calls.last, 'stop');
  });

  test(
    'transition after boundary request is rejected without queue adoption',
    () async {
      await root.playNativeSequence('q0');
      root.setContinueAfterTrack(false);
      engine.tick(1, 20);
      await flush();
      expect(root.state.queue.currentEntryId, 'q0');
      expect(root.state.phase, PlaybackPhase.error);
      expect(engine.calls.last, 'stop');
    },
  );

  test(
    'manual next leaves sequence and uses existing explicit entry path',
    () async {
      await root.playNativeSequence('q0');
      await root.skipNext();
      expect(root.state.queue.currentEntryId, 'q1');
      expect(engine.calls, containsAllInOrder(['stop', 'load', 'play']));
    },
  );

  test(
    'unknown batch snapshots cannot move the root or write the queue',
    () async {
      await root.playNativeSequence('q0');
      final foreign = AudioSequence(engine.sequence!.entries);
      engine.inner.events.add(
        AudioEngineState(
          phase: AudioEnginePhase.playing,
          sequenceCursor: foreign.cursors.last,
        ),
      );
      await flush();
      expect(root.state.queue.currentEntryId, 'q0');
      expect(collection.queueWrites, isEmpty);
    },
  );

  test('close while transition write waits drains accepted storage without late UI', () async {
    await root.playNativeSequence('q0');
    final gate = Completer<void>();
    collection.beforeQueueWrite = (_) => gate.future;
    engine.tick(1, 10);
    await flush();
    final closing = root.close();
    gate.complete();
    await closing;
    expect(root.state.queue.currentEntryId, 'q0');
    expect((await collection.loadQueue()).currentEntryId, 'q1');
  });
}

Future<void> flush() async {
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

final class NativeEngine implements AudioSequenceEngine {
  final inner = FakeAudioEngine();
  final calls = <String>[];
  AudioSequence? sequence;
  int index = 0;
  Completer<void>? loadGate;
  bool retainResult = true;
  @override
  bool get isAvailable => true;
  @override
  bool get supportsSequences => true;
  @override
  Stream<AudioEngineState> get states => inner.states.map(
    (state) => AudioEngineState(
      phase: state.phase,
      position: state.position,
      buffered: state.buffered,
      duration: state.duration,
      volume: state.volume,
      playbackRate: state.playbackRate,
      failure: state.failure,
      sequenceCursor: state.sequenceCursor ?? sequence?.cursors[index],
    ),
  );
  @override
  Future<void> loadSequence(AudioSequence value, {int initialIndex = 0}) async {
    calls.add('sequence:${value.entries.length}');
    sequence = value;
    index = initialIndex;
    if (loadGate != null) await loadGate!.future;
    await inner.load(value.entries[index].source);
  }

  @override
  Future<bool> retainSequenceThrough(AudioSequenceCursor expected) async {
    calls.add('retain:${expected.index}');
    return retainResult &&
        identical(expected.sequenceIdentity, sequence?.identity) &&
        index == expected.index;
  }

  @override
  Future<void> load(PlayableSource value) async {
    calls.add('load');
    sequence = null;
    await inner.load(value);
  }

  @override
  Future<void> play() async {
    calls.add('play');
    await inner.play();
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    await inner.pause();
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    sequence = null;
    await inner.stop();
  }

  @override
  Future<void> seek(Duration value) async {
    calls.add('seek');
    await inner.seek(value);
  }

  @override
  Future<void> setVolume(double value) => inner.setVolume(value);
  @override
  Future<void> setPlaybackRate(double value) => inner.setPlaybackRate(value);
  @override
  Future<void> dispose() => inner.dispose();
  void tick(int target, int millis) {
    index = target;
    inner.position = Duration(milliseconds: millis);
    inner.events.add(
      AudioEngineState(
        phase: AudioEnginePhase.playing,
        position: Duration(milliseconds: millis),
        duration: const Duration(minutes: 3),
      ),
    );
  }

  void complete() => inner.complete();
}

final class GatedResolver implements PlaybackSourceResolver {
  Completer<void>? gate;
  String? gateTrack;
  @override
  Future<PlayableSource> resolve(Track track) async {
    if (track.id == gateTrack && gate != null) await gate!.future;
    return FakePlaybackSourceResolver().resolve(track);
  }
}
