import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/just_audio_engine.dart';
import 'package:yymusic/playback/playable_source.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_source_resolver.dart';
import 'package:yymusic/playback/playback_state.dart';

import 'support/deterministic_pcm_wav.dart';
import 'support/probe_signal_wait.dart';
import 'support/root_native_shuffle_result.dart';

const _deadline = Duration(seconds: 25);
const _seed = 42;

/// Independent Android fixture; never opens production data or changes outputs.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const commit = String.fromEnvironment('YYMUSIC_ROOT_SHUFFLE_SOURCE_COMMIT');
  Map<String, Object>? metrics;
  testWidgets(
    'root native shuffle crosses a cycle and honors explicit disable',
    (_) async {
      expect(Platform.isAndroid, true);
      expect(RegExp(r'^[0-9a-f]{40}$').hasMatch(commit), true);
      final directory = await Directory.systemTemp.createTemp(
        'yy-root-shuffle-',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true).timeout(_deadline);
        }
      });
      final tracks = <Track>[];
      for (var i = 0; i < 3; i++) {
        final file = File(
          '${directory.path}${Platform.pathSeparator}tone-$i.wav',
        );
        await file
            .writeAsBytes(
              buildDeterministicPcmWav(
                duration: const Duration(seconds: 10),
                frequencyHz: 440 + i * 110,
              ),
              flush: true,
            )
            .timeout(_deadline);
        tracks.add(
          Track(
            id: 'tone-$i',
            sourceId: 'root-native-shuffle-poc',
            sourceType: MusicSourceType.local,
            title: 'Root shuffle tone $i',
            artists: const ['Generated fixture'],
            duration: const Duration(seconds: 10),
            localPath: file.path,
          ),
        );
      }
      final databaseFile = File(
        '${directory.path}${Platform.pathSeparator}probe.sqlite',
      );
      final data = await DatabaseAppDataServices.open(
        AppDatabase(NativeDatabase.createInBackground(databaseFile)),
      ).timeout(_deadline);
      addTearDown(() => data.dispose().timeout(_deadline));
      await data.library.upsertTracks(tracks).timeout(_deadline);
      final engine = JustAudioEngine.create(
        useProxyForRequestHeaders: false,
        supportsRequestHeaders: false,
      );
      addTearDown(() => engine.dispose().timeout(_deadline));
      final random = Random(_seed), randomChoices = <int>[];
      var randomCalls = 0;
      final root = PlaybackController(
        engine,
        library: data.library,
        collection: data.collection,
        sourceResolver: _ShuffleFixtureResolver(tracks),
        randomIndex: (upperBound) {
          final value = random.nextInt(upperBound);
          randomCalls++;
          if (randomChoices.length < 4) randomChoices.add(value);
          return value;
        },
      );
      addTearDown(() => root.close().timeout(_deadline));
      final changes = StreamController<void>.broadcast(sync: true);
      addTearDown(changes.close);
      void changed() => changes.add(null);
      AudioEngineState? native;
      Object? batch;
      var failed = false, engineClosed = false;
      var sameNativeBatch = true, metadataAligned = true, queueUnchanged = true;
      var modeChanged = false,
          boundaryCompleted = false,
          shuffleStayedDisabled = true;
      var watchingCompletion = false, restarted = false;
      final nativeEntries = <String>[],
          nativeIndices = <int>[],
          nativeCycles = <int>[];
      final rootEntries = <String>[];
      final engineSubscription = engine.states.listen(
        (state) {
          native = state;
          failed |= state.phase == AudioEnginePhase.error;
          if (watchingCompletion && state.phase != AudioEnginePhase.completed) {
            restarted = true;
          }
          final cursor = state.sequenceCursor;
          if (cursor != null) {
            batch ??= cursor.sequenceIdentity;
            sameNativeBatch &= identical(batch, cursor.sequenceIdentity);
            if (state.phase == AudioEnginePhase.playing &&
                (nativeIndices.isEmpty || nativeIndices.last != cursor.index)) {
              if (nativeIndices.length < 8) {
                nativeEntries.add(cursor.entryId);
                nativeIndices.add(cursor.index);
                nativeCycles.add(cursor.cycle);
              } else {
                failed = true;
              }
            }
            if (modeChanged &&
                state.phase == AudioEnginePhase.completed &&
                cursor.entryId == 'q1' &&
                cursor.index == 3 &&
                cursor.cycle == 1) {
              boundaryCompleted = true;
            }
          }
          changed();
        },
        onError: (Object _) {
          failed = true;
          changed();
        },
        onDone: () {
          engineClosed = true;
          changed();
        },
      );
      addTearDown(engineSubscription.cancel);
      void rootChanged() {
        final state = root.state,
            id = state.queue.currentEntryId,
            track = state.currentTrack;
        failed |=
            state.phase == PlaybackPhase.error || root.history.failure != null;
        if (modeChanged) shuffleStayedDisabled &= !state.shuffleEnabled;
        if (track != null) {
          final index = ['q0', 'q1', 'q2'].indexOf(id ?? '');
          metadataAligned &=
              index >= 0 &&
              track.ref == tracks[index].ref &&
              track.title == tracks[index].title;
        }
        if (state.phase == PlaybackPhase.playing) {
          metadataAligned &= track != null;
          if (id != null && (rootEntries.isEmpty || rootEntries.last != id)) {
            if (rootEntries.length < 8) {
              rootEntries.add(id);
            } else {
              failed = true;
            }
          }
        }
        if (watchingCompletion && state.phase != PlaybackPhase.completed) {
          restarted = true;
        }
        changed();
      }

      root.addListener(rootChanged);
      root.history.addListener(rootChanged);
      addTearDown(() {
        root.removeListener(rootChanged);
        root.history.removeListener(rootChanged);
      });
      Future<void> waitFor(bool Function() condition) async {
        await waitForProbeSignal(
          changes.stream,
          () => failed || condition(),
          _deadline,
        );
        expect(failed, false, reason: 'Native/root/history failure');
        expect(condition(), true);
      }

      final persistedEntries = <String>[];
      Future<void> checkQueue(String id) async {
        final saved = await data.collection.loadQueue().timeout(_deadline);
        expect(saved.currentEntryId, id);
        expect(saved.entries.map((e) => e.id), ['q0', 'q1', 'q2']);
        expect(saved.entries.map((e) => e.track), tracks.map((t) => t.ref));
        expect(saved.entries.map((e) => e.position), [0, 1, 2]);
        queueUnchanged &=
            saved.entries.length == 3 &&
            saved.entries.indexed.every(
              (e) =>
                  e.$2.id == 'q${e.$1}' &&
                  e.$2.track == tracks[e.$1].ref &&
                  e.$2.position == e.$1,
            );
        persistedEntries.add(saved.currentEntryId!);
      }

      await root.initialize().timeout(_deadline);
      await root
          .replaceQueue([
            for (var i = 0; i < 3; i++)
              QueueEntry(
                id: 'q$i',
                track: tracks[i].ref,
                position: i,
                addedAt: DateTime.now().toUtc(),
              ),
          ], currentEntryId: 'q0')
          .timeout(_deadline);
      root.setShuffleEnabled(true);
      root.setRepeatMode(RepeatMode.all);
      await root.setVolume(0.05).timeout(_deadline);
      await root.playNativeSequence('q0').timeout(_deadline);
      final nativeProgress = <int>[], rootProgress = <int>[];
      const expectedIds = ['q0', 'q1', 'q2', 'q1'];
      for (var i = 0; i < expectedIds.length; i++) {
        final id = expectedIds[i], trackIndex = [0, 1, 2, 1][i];
        await waitFor(
          () =>
              native?.phase == AudioEnginePhase.playing &&
              native?.sequenceCursor?.index == i &&
              native?.sequenceCursor?.cycle == (i == 3 ? 1 : 0) &&
              native!.position >= const Duration(milliseconds: 100) &&
              root.state.phase == PlaybackPhase.playing &&
              root.state.queue.currentEntryId == id &&
              root.state.currentTrack?.ref == tracks[trackIndex].ref &&
              root.state.position >= const Duration(milliseconds: 100),
        );
        expect(root.state.shuffleEnabled, true);
        nativeProgress.add(native!.position.inMilliseconds);
        rootProgress.add(root.state.position.inMilliseconds);
        await checkQueue(id);
      }
      expect(randomChoices.take(2), [1, 0]);
      final modeCursor = native!.sequenceCursor!;
      final beforeModePosition = native!.position;
      root.setShuffleEnabled(false);
      modeChanged = true;
      final callsAtChange = randomCalls;
      expect(root.state.shuffleEnabled, false);
      // A policy change must retain the currently playing item, not reload it.
      await waitFor(
        () =>
            native?.phase == AudioEnginePhase.playing &&
            identical(native?.sequenceCursor?.sequenceIdentity, batch) &&
            native?.sequenceCursor?.index == 3 &&
            root.state.queue.currentEntryId == 'q1' &&
            root.state.phase == PlaybackPhase.playing &&
            native!.position - beforeModePosition >=
                const Duration(milliseconds: 100),
      );
      final continuedCurrent =
          identical(native!.sequenceCursor?.sequenceIdentity, batch) &&
          native!.sequenceCursor?.index == modeCursor.index;
      final boundaryDelta =
          (native!.position - beforeModePosition).inMilliseconds;
      // The old shuffled suffix is q0, while the sequential successor of q1 is q2.
      // The root must naturally finish retained q1 and load q2 via its existing path.
      await waitFor(
        () =>
            boundaryCompleted &&
            native?.phase == AudioEnginePhase.playing &&
            native?.sequenceCursor == null &&
            native!.position >= const Duration(milliseconds: 100) &&
            root.state.phase == PlaybackPhase.playing &&
            root.state.queue.currentEntryId == 'q2' &&
            root.state.currentTrack?.ref == tracks[2].ref &&
            root.state.position >= const Duration(milliseconds: 100),
      );
      final singleProgress = native!.position.inMilliseconds;
      rootProgress.add(root.state.position.inMilliseconds);
      final sequentialFallback =
          native!.sequenceCursor == null &&
          root.state.queue.currentEntryId == 'q2';
      root.setContinueAfterTrack(false);
      await checkQueue('q2');
      await waitFor(
        () =>
            native?.phase == AudioEnginePhase.completed &&
            root.state.phase == PlaybackPhase.completed &&
            !root.history.busy,
      );
      expect(native!.sequenceCursor, isNull);
      final completedEntry = root.state.queue.currentEntryId;
      expect(completedEntry, 'q2');
      expect(root.continueAfterTrack, false);
      watchingCompletion = true;
      final quiet = Stopwatch()..start();
      await expectLater(
        waitForProbeSignal(
          changes.stream,
          () => failed || restarted,
          const Duration(milliseconds: 1200),
        ),
        throwsA(isA<TimeoutException>()),
      );
      final quietMs = quiet.elapsedMilliseconds;
      expect(failed || restarted, false);
      watchingCompletion = false;
      expect(nativeEntries, ['q0', 'q1', 'q2', 'q1']);
      expect(nativeIndices, [0, 1, 2, 3]);
      expect(nativeCycles, [0, 0, 0, 1]);
      expect(rootEntries, ['q0', 'q1', 'q2', 'q1', 'q2']);
      expect(
        sameNativeBatch &&
            metadataAligned &&
            queueUnchanged &&
            shuffleStayedDisabled,
        true,
      );
      final randomStopped = randomCalls == callsAtChange;
      expect(randomStopped, true);
      await root.close().timeout(_deadline);
      await engine.dispose().timeout(_deadline);
      await data.dispose().timeout(_deadline);
      expect(
        root.isClosed && engineClosed && !engine.isAvailable && !failed,
        true,
      );
      metrics = {
        'sourceCommit': commit,
        'platform': Platform.operatingSystem,
        'randomSeed': _seed,
        'randomPrefix': randomChoices.take(2).toList(),
        'randomCallsAtChange': callsAtChange,
        'nativeEntries': nativeEntries,
        'nativeIndices': nativeIndices,
        'nativeCycles': nativeCycles,
        'rootEntries': rootEntries,
        'persistedEntries': persistedEntries,
        'nativeProgressMs': nativeProgress,
        'rootProgressMs': rootProgress,
        'singleProgressMs': singleProgress,
        'boundaryProgressDeltaMs': boundaryDelta,
        'sameNativeBatch': sameNativeBatch,
        'metadataAligned': metadataAligned,
        'queueUnchanged': queueUnchanged,
        'boundaryCompleted': boundaryCompleted,
        'continuedCurrentWithoutReload': continuedCurrent,
        'sequentialFallback': sequentialFallback,
        'shuffleStayedDisabled': shuffleStayedDisabled,
        'randomStopped': randomStopped,
        'disposed': root.isClosed && engineClosed && !engine.isAvailable,
        'modeChangeIndex': modeCursor.index,
        'modeChangeEntry': modeCursor.entryId,
        // Oracle from the asserted seeded order, not a backend-buffer inspection.
        'expectedRevokedNextEntry': 'q0',
        'sequentialNextEntry': rootEntries.last,
        'completedEntry': completedEntry!,
        'noRestartObservedMs': quietMs,
        'acousticGapMeasured': false,
      };
      expect(
        rootNativeShuffleResult(
          sourceCommit: commit,
          testsPassed: true,
          testCount: 1,
          metrics: metrics,
        )['passed'],
        true,
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
  unawaited(() async {
    var passed = false;
    try {
      passed = await binding.allTestsPassed.future.timeout(
        const Duration(minutes: 4),
      );
    } catch (_) {
      /* Emit only the fixed failure diagnostic. */
    }
    if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(commit)) return;
    final result = rootNativeShuffleResult(
      sourceCommit: commit,
      testsPassed: passed,
      testCount: binding.results.length,
      metrics: metrics,
    );
    debugPrintSynchronously(
      'YYMUSIC_ROOT_NATIVE_SHUFFLE_RESULT ${jsonEncode(result)}',
    );
  }());
}

/// The resolver has authority only over this test's three generated references.
final class _ShuffleFixtureResolver implements PlaybackSourceResolver {
  _ShuffleFixtureResolver(this.tracks);
  final List<Track> tracks;
  @override
  Future<PlayableSource> resolve(Track track) async {
    final fixture = tracks.singleWhere((t) => t.ref == track.ref);
    if (track.localPath != fixture.localPath) {
      throw StateError('Fixture mismatch');
    }
    return PlayableSource.localFile(
      track: fixture.ref,
      path: fixture.localPath!,
    );
  }
}
