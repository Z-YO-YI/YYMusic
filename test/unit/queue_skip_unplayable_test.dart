import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/playable_source.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_source_resolver.dart';
import 'package:yymusic/playback/playback_state.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';

Track track(
  String id, [
  TrackAvailability availability = TrackAvailability.available,
]) => Track(
  id: id,
  sourceId: 'fixture',
  sourceType: MusicSourceType.rest,
  title: id,
  artists: const ['Fixture'],
  duration: const Duration(minutes: 2),
  availability: availability,
);

final class Resolver implements PlaybackSourceResolver {
  final failures = <String, DomainFailure>{};
  final calls = <String>[];
  Future<void>? gate;
  @override
  Future<PlayableSource> resolve(Track value) async {
    calls.add(value.id);
    await gate;
    if (failures[value.id] case final failure?) throw failure;
    return FakePlaybackSourceResolver().resolve(value);
  }
}

Future<void> flushQueue() async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeAudioEngine engine;
  late FakeLibraryRepository library;
  late PlaybackController root;
  late Resolver resolver;
  setUp(() {
    engine = FakeAudioEngine();
    library = FakeLibraryRepository(
      tracks: [track('first'), track('bad'), track('last')],
    );
    resolver = Resolver();
    root = PlaybackController(
      engine,
      library: library,
      sourceResolver: resolver,
      randomIndex: (upper) => upper - 1,
    );
  });
  tearDown(() async {
    await root.close();
    await engine.dispose();
    await library.dispose();
  });
  Future<void> queue([
    List<String> ids = const ['first', 'bad', 'last'],
  ]) async {
    await root.replaceQueue([
      for (final (index, id) in ids.indexed)
        QueueEntry(
          id: 'entry-$id',
          track: track(id).ref,
          position: index,
          addedAt: DateTime.utc(2026),
        ),
    ]);
    await root.play();
    resolver.calls.clear();
    engine.calls.clear();
  }

  for (final shuffle in [false, true]) {
    test(
      'natural completion skips unavailable source, shuffle=$shuffle',
      () async {
        resolver.failures['bad'] = DomainFailure(
          code: DomainFailureCode.sourceRemoved,
          diagnosticId: 'fixture.removed',
        );
        await queue();
        root.setShuffleEnabled(shuffle);
        engine.complete();
        await flushQueue();
        expect(root.state.queue.currentEntryId, 'entry-last');
        expect(root.state.phase, PlaybackPhase.playing);
        expect(root.queuePlaybackFailures.single.entryId, 'entry-bad');
        expect(
          root.queuePlaybackFailures.single.code,
          DomainFailureCode.sourceRemoved,
        );
        expect(root.state.queue.entries.length, 3);
        expect(resolver.calls, ['bad', 'last']);
        expect(engine.calls.where((call) => call == 'play').length, 1);
      },
    );
  }

  test('missing soft reference is skipped without deleting it', () async {
    await queue(['first', 'missing', 'last']);
    await root.skipNext();
    expect(root.state.queue.currentEntryId, 'entry-last');
    expect(root.queuePlaybackFailures.single.code, DomainFailureCode.notFound);
    expect(root.state.queue.entries.length, 3);
  });

  for (final availability in TrackAvailability.values.where(
    (value) => value != TrackAvailability.available,
  )) {
    test(
      'metadata $availability is skipped before source resolution',
      () async {
        await library.upsertTracks([track('bad', availability)]);
        await queue();
        await root.skipNext();
        expect(resolver.calls, ['last']);
        expect(root.queuePlaybackFailures.single.entryId, 'entry-bad');
        expect(root.state.queue.currentEntryId, 'entry-last');
      },
    );
  }

  test('stop failure is not mistaken for a bad candidate load', () async {
    await queue();
    engine.stopError = DomainFailure(
      code: DomainFailureCode.playbackOpenFailed,
      diagnosticId: 'fixture.stop',
    );
    await expectLater(root.skipNext(), throwsA(isA<DomainFailure>()));
    expect(resolver.calls, ['bad']);
    expect(root.queuePlaybackFailures, isEmpty);
    engine.stopError = null;
  });

  test(
    'manual next skips failed entries while automatic continuation disabled',
    () async {
      await queue(['first', 'missing', 'last']);
      root.setContinueAfterTrack(false);
      await root.skipNext();
      expect(root.state.queue.currentEntryId, 'entry-last');
    },
  );

  test(
    'explicit selection still reports failure instead of choosing another song',
    () async {
      await queue(['first', 'missing', 'last']);
      await expectLater(
        root.playEntry('entry-missing'),
        throwsA(isA<DomainFailure>()),
      );
      expect(root.queuePlaybackFailures, isEmpty);
      expect(resolver.calls, isEmpty);
    },
  );

  for (final code in [
    DomainFailureCode.databaseCorrupted,
    DomainFailureCode.unknown,
    DomainFailureCode.unauthorized,
    DomainFailureCode.networkOffline,
  ]) {
    test('global or unsafe failure $code stops traversal', () async {
      await queue();
      resolver.failures['bad'] = DomainFailure(
        code: code,
        diagnosticId: 'fixture.failure',
      );
      await expectLater(root.skipNext(), throwsA(isA<DomainFailure>()));
      expect(resolver.calls, ['bad']);
      expect(root.queuePlaybackFailures, isEmpty);
    });
  }

  test(
    'repeat all cannot spin forever when every remaining source fails',
    () async {
      await queue();
      root.setRepeatMode(RepeatMode.all);
      for (final id in ['first', 'bad', 'last']) {
        resolver.failures[id] = DomainFailure(
          code: DomainFailureCode.playbackOpenFailed,
          diagnosticId: 'fixture.open',
        );
      }
      await expectLater(root.skipNext(), throwsA(isA<DomainFailure>()));
      expect(resolver.calls, ['bad', 'last', 'first']);
      expect(root.queuePlaybackFailures.length, 3);
      expect(root.state.phase, PlaybackPhase.error);
    },
  );

  test(
    'turning continuation off in failure notification stops further attempts',
    () async {
      await queue(['first', 'missing', 'last']);
      root.addListener(() {
        if (root.state.phase == PlaybackPhase.error) {
          root.setContinueAfterTrack(false);
        }
      });
      engine.complete();
      await flushQueue();
      expect(resolver.calls, isEmpty);
      expect(root.queuePlaybackFailures.length, 1);
      expect(engine.calls.where((call) => call == 'play'), isEmpty);
    },
  );

  test('audio load failures are bounded and recorded', () async {
    await queue();
    engine.loadError = DomainFailure(
      code: DomainFailureCode.unsupportedAudioFormat,
      diagnosticId: 'fixture.load',
    );
    await expectLater(root.skipNext(), throwsA(isA<DomainFailure>()));
    expect(resolver.calls, ['bad', 'last']);
    expect(root.queuePlaybackFailures.length, 2);
  });

  test('recent diagnostics retain only 20 immutable entries', () async {
    await queue(['first', for (var i = 0; i < 25; i++) 'missing-$i']);
    await expectLater(root.skipNext(), throwsA(isA<DomainFailure>()));
    expect(root.queuePlaybackFailures.length, 20);
    expect(root.queuePlaybackFailures.first.entryId, 'entry-missing-5');
    expect(() => root.queuePlaybackFailures.clear(), throwsUnsupportedError);
  });

  test(
    'closing during resolver failure does not attempt later candidates',
    () async {
      await queue();
      final gate = Completer<void>();
      resolver.gate = gate.future;
      resolver.failures['bad'] = DomainFailure(
        code: DomainFailureCode.notFound,
        diagnosticId: 'fixture.missing',
      );
      final advancing = root.skipNext();
      await flushQueue();
      final closing = root.close();
      gate.complete();
      await advancing;
      await closing;
      expect(resolver.calls, ['bad']);
      expect(engine.calls.where((call) => call == 'play'), isEmpty);
    },
  );
}
