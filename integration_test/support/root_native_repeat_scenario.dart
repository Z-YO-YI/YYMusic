import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
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

import 'deterministic_pcm_wav.dart';
import 'probe_signal_wait.dart';
import 'root_native_repeat_metrics.dart';

const _deadline = Duration(seconds: 25);
const _quietWindow = Duration(milliseconds: 1200);

/// Shared device scenario; each isolated entry fixes its expected platform.
void registerRootNativeRepeatScenario({
  required String sourceCommit,
  required RootRepeatPlatform platform,
  required void Function(Map<String, Object>) onMetrics,
}) {
  final commit = sourceCommit;
  testWidgets(
    'root native repeat persists history and stops at current boundary',
    (_) async {
      expect(Platform.operatingSystem, platform.name);
      expect(RegExp(r'^[0-9a-f]{40}$').hasMatch(commit), isTrue);
      final directory = await Directory.systemTemp.createTemp(
        'yy-root-repeat-',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true).timeout(_deadline);
        }
      });
      final tracks = <Track>[];
      for (var i = 0; i < 2; i++) {
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
            sourceId: 'root-native-repeat-poc',
            sourceType: MusicSourceType.local,
            title: 'Root native tone $i',
            artists: const ['Generated fixture'],
            duration: const Duration(seconds: 10),
            localPath: file.path,
          ),
        );
      }
      final databaseFile = File(
        '${directory.path}${Platform.pathSeparator}probe.sqlite',
      );
      Future<DatabaseAppDataServices> openData() =>
          DatabaseAppDataServices.open(
            AppDatabase(NativeDatabase.createInBackground(databaseFile)),
          ).timeout(_deadline);
      final data = await openData();
      addTearDown(() => data.dispose().timeout(_deadline));
      await data.library.upsertTracks(tracks).timeout(_deadline);
      final engine = JustAudioEngine.create(
        useProxyForRequestHeaders: false,
        supportsRequestHeaders: false,
      );
      addTearDown(() => engine.dispose().timeout(_deadline));
      final resolver = _FixtureResolver(tracks);
      final root = PlaybackController(
        engine,
        library: data.library,
        collection: data.collection,
        sourceResolver: resolver,
      );
      addTearDown(() => root.close().timeout(_deadline));
      final changes = StreamController<void>.broadcast(sync: true);
      addTearDown(changes.close);
      void changed() => changes.add(null);
      AudioEngineState? native;
      Object? batch;
      var sameNativeBatch = true, metadataAligned = true;
      var failed = false, engineClosed = false;
      final nativeEntries = <String>[],
          nativeIndices = <int>[],
          nativeCycles = <int>[];
      final rootEntries = <String>[];
      List<PlayHistoryEntry> history = [];
      var watchingCompletion = false, restarted = false;
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
        final state = root.state;
        failed |=
            state.phase == PlaybackPhase.error || root.history.failure != null;
        final id = state.queue.currentEntryId;
        final track = state.currentTrack;
        if (track != null) {
          final index = id == 'q0'
              ? 0
              : id == 'q1'
              ? 1
              : -1;
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
      final historySubscription = data.collection.watchHistory().listen(
        (value) {
          history = value;
          changed();
        },
        onError: (Object _) {
          failed = true;
          changed();
        },
      );
      addTearDown(historySubscription.cancel);
      Future<void> waitFor(bool Function() condition) async {
        bool ready() => failed || condition();
        await waitForProbeSignal(changes.stream, ready, _deadline);
        expect(failed, isFalse, reason: 'Native/root/history failure');
        expect(condition(), isTrue);
      }

      Future<int> observeQuiet(bool Function() forbidden) async {
        final elapsed = Stopwatch()..start();
        expect(failed || forbidden(), isFalse);
        await expectLater(
          waitForProbeSignal(
            changes.stream,
            () => failed || forbidden(),
            _quietWindow,
          ),
          throwsA(isA<TimeoutException>()),
        );
        expect(failed || forbidden(), isFalse);
        return elapsed.elapsedMilliseconds;
      }

      await root.initialize().timeout(_deadline);
      await root
          .replaceQueue([
            for (var i = 0; i < 2; i++)
              QueueEntry(
                id: 'q$i',
                track: tracks[i].ref,
                position: i,
                addedAt: DateTime.now().toUtc(),
              ),
          ], currentEntryId: 'q0')
          .timeout(_deadline);
      root.setRepeatMode(RepeatMode.all);
      await root.setVolume(0.05).timeout(_deadline);
      expect(
        await data.collection.watchHistory().first.timeout(_deadline),
        isEmpty,
      );
      await root.playNativeSequence('q0').timeout(_deadline);
      final nativeProgress = <int>[], rootProgress = <int>[];
      final persistedEntries = <String>[];
      String? initialHistoryId;
      DateTime? initialHistoryTime;
      var historyReplaced = false;
      for (var i = 0; i < 3; i++) {
        final trackIndex = i % 2, expectedId = 'q${i % 2}';
        await waitFor(
          () =>
              native?.phase == AudioEnginePhase.playing &&
              native?.sequenceCursor?.index == i &&
              native?.sequenceCursor?.cycle == i ~/ 2 &&
              native!.position >= const Duration(milliseconds: 100) &&
              root.state.phase == PlaybackPhase.playing &&
              root.state.queue.currentEntryId == expectedId &&
              root.state.currentTrack?.ref == tracks[trackIndex].ref &&
              root.state.position >= const Duration(milliseconds: 100),
        );
        nativeProgress.add(native!.position.inMilliseconds);
        rootProgress.add(root.state.position.inMilliseconds);
        if (i == 2) root.setContinueAfterTrack(false);
        final saved = await data.collection.loadQueue().timeout(_deadline);
        expect(saved.currentEntryId, expectedId);
        expect(saved.entries.map((e) => e.id), ['q0', 'q1']);
        expect(saved.entries.map((e) => e.track), tracks.map((t) => t.ref));
        persistedEntries.add(saved.currentEntryId!);
        await waitFor(
          () => history.any(
            (e) =>
                e.track == tracks[trackIndex].ref &&
                e.lastPosition > Duration.zero &&
                (i != 2 || e.id != initialHistoryId),
          ),
        );
        final heard = history.singleWhere(
          (e) => e.track == tracks[trackIndex].ref,
        );
        if (i == 0) {
          initialHistoryId = heard.id;
          initialHistoryTime = heard.startedAt;
        } else if (i == 2) {
          historyReplaced =
              heard.id != initialHistoryId &&
              heard.startedAt.isAfter(initialHistoryTime!);
          expect(historyReplaced, isTrue);
          expect(history, hasLength(2));
          expect(history.first.track, tracks[0].ref);
        }
      }
      await waitFor(
        () =>
            native?.phase == AudioEnginePhase.completed &&
            root.state.phase == PlaybackPhase.completed &&
            !root.history.busy,
      );
      final completed = native!.sequenceCursor!;
      expect(completed.entryId, 'q0');
      expect(completed.index, 2);
      expect(completed.cycle, 1);
      expect(root.continueAfterTrack, isFalse);
      watchingCompletion = true;
      final quietMs = await observeQuiet(() => restarted);
      watchingCompletion = false;
      expect(nativeEntries, ['q0', 'q1', 'q0']);
      expect(nativeIndices, [0, 1, 2]);
      expect(nativeCycles, [0, 0, 1]);
      expect(rootEntries, ['q0', 'q1', 'q0']);
      expect(sameNativeBatch && metadataAligned, isTrue);
      final historyCount = history.length;
      final lastHistory = history.map((e) => e.id).toList();
      await root.close().timeout(_deadline);
      await engine.dispose().timeout(_deadline);
      expect(root.isClosed && engineClosed && !engine.isAvailable, isTrue);
      await historySubscription.cancel();
      await data.dispose().timeout(_deadline);

      // Reopen the file database, not just another facade over an in-memory store.
      final restoredData = await openData();
      addTearDown(() => restoredData.dispose().timeout(_deadline));
      final restoredEngine = JustAudioEngine.create(
        useProxyForRequestHeaders: false,
        supportsRequestHeaders: false,
      );
      addTearDown(() => restoredEngine.dispose().timeout(_deadline));
      final restoredResolver = _FixtureResolver(tracks);
      final restored = PlaybackController(
        restoredEngine,
        library: restoredData.library,
        collection: restoredData.collection,
        sourceResolver: restoredResolver,
      );
      addTearDown(() => restored.close().timeout(_deadline));
      var restoredWithoutPlayback = true;
      final restoredSubscription = restoredEngine.states.listen(
        (state) {
          restoredWithoutPlayback &=
              state.phase == AudioEnginePhase.idle &&
              state.position == Duration.zero &&
              state.sequenceCursor == null;
          changed();
        },
        onError: (Object _) {
          failed = true;
          changed();
        },
      );
      addTearDown(restoredSubscription.cancel);
      await restored.initialize().timeout(_deadline);
      expect(restored.state.queue.entries.map((e) => e.id), ['q0', 'q1']);
      expect(
        restored.state.queue.entries.map((e) => e.track),
        tracks.map((t) => t.ref),
      );
      final restoredEntry = restored.state.queue.currentEntryId;
      expect(restoredEntry, 'q0');
      expect(restored.state.currentTrack, isNull);
      expect(restored.state.phase, PlaybackPhase.idle);
      final restoreMs = await observeQuiet(
        () =>
            !restoredWithoutPlayback ||
            restoredResolver.calls != 0 ||
            restored.state.phase != PlaybackPhase.idle,
      );
      expect(
        (await restoredData.collection.watchHistory().first.timeout(_deadline))
            .map((e) => e.id),
        lastHistory,
      );
      await restored.close().timeout(_deadline);
      await restoredEngine.dispose().timeout(_deadline);
      await restoredSubscription.cancel();
      await restoredData.dispose().timeout(_deadline);
      expect(failed, isFalse);
      final metrics = <String, Object>{
        'sourceCommit': commit,
        'platform': Platform.operatingSystem,
        'nativeEntries': nativeEntries,
        'nativeIndices': nativeIndices,
        'nativeCycles': nativeCycles,
        'rootEntries': rootEntries,
        'persistedEntries': persistedEntries,
        'nativeProgressMs': nativeProgress,
        'rootProgressMs': rootProgress,
        'sameNativeBatch': sameNativeBatch,
        'metadataAligned': metadataAligned,
        'historyCount': historyCount,
        'historyReplaced': historyReplaced,
        'completedEntry': completed.entryId,
        'completedIndex': completed.index,
        'completedCycle': completed.cycle,
        'noRestartObservedMs': quietMs,
        'restoreObservedMs': restoreMs,
        'restoredEntry': restoredEntry!,
        'restoredWithoutPlayback': restoredWithoutPlayback,
        'disposed':
            root.isClosed &&
            restored.isClosed &&
            !engine.isAvailable &&
            !restoredEngine.isAvailable,
        'acousticGapMeasured': false,
      };
      expect(
        projectRootNativeRepeatMetrics(
          sourceCommit: commit,
          platform: platform,
          metrics: metrics,
        ),
        isNotNull,
      );
      onMetrics(metrics);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

/// Only resolves the two generated fixture references; never opens user media.
final class _FixtureResolver implements PlaybackSourceResolver {
  _FixtureResolver(this.tracks);
  final List<Track> tracks;
  int calls = 0;

  @override
  Future<PlayableSource> resolve(Track track) async {
    final fixture = tracks.singleWhere((item) => item.ref == track.ref);
    if (track.localPath != fixture.localPath) {
      throw StateError('Fixture mismatch');
    }
    calls++;
    return PlayableSource.localFile(
      track: fixture.ref,
      path: fixture.localPath!,
    );
  }
}
