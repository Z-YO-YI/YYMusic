import 'dart:async';

import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_history_recorder.dart';

import 'catalog_detail_probe.dart';
import 'fake_audio_engine.dart';
import 'fake_domain_repositories.dart';
import 'fake_playback_dependencies.dart';
import 'playlist_content_probe.dart';

AudioEngineState historyState(
  int milliseconds, {
  AudioEnginePhase phase = AudioEnginePhase.playing,
}) => AudioEngineState(
  phase: phase,
  position: Duration(milliseconds: milliseconds),
  duration: const Duration(seconds: 120),
);

Future<void> waitHistory(PlaybackHistoryRecorder recorder) async {
  if (!recorder.busy) return;
  final done = Completer<void>();
  void check() {
    if (!recorder.busy && !done.isCompleted) done.complete();
  }

  recorder.addListener(check);
  try {
    check();
    await done.future.timeout(const Duration(seconds: 5));
  } finally {
    recorder.removeListener(check);
  }
}

final class PlaybackHistoryFixture {
  PlaybackHistoryFixture() {
    library = FakeLibraryRepository(tracks: tracks);
    collection.onHistoryRecord = (entry) async {
      writes.add(entry);
      await writeGate;
      if (writeError != null) throw writeError!;
    };
    player = PlaybackController(
      engine,
      library: library,
      collection: collection,
      sourceResolver: FakePlaybackSourceResolver(),
      clock: () => now,
      historyIdFactory: () => 'record-${sequence++}',
    );
  }
  final tracks = [detailTrack('a'), detailTrack('b')];
  final engine = FakeAudioEngine();
  final collection = FakeCollectionRepository();
  late final FakeLibraryRepository library;
  late final PlaybackController player;
  DateTime now = contentEpoch;
  int sequence = 0;
  final writes = <PlayHistoryEntry>[];
  Future<void>? writeGate;
  Object? writeError;
  Future<void> initialize() async {
    await player.initialize();
    await player.replaceQueue([
      for (var i = 0; i < tracks.length; i++)
        QueueEntry(id: 'q-$i', track: tracks[i].ref, position: i, addedAt: now),
    ], currentEntryId: 'q-0');
  }

  void tick(
    int milliseconds, {
    AudioEnginePhase phase = AudioEnginePhase.playing,
  }) {
    engine.position = Duration(milliseconds: milliseconds);
    engine.events.add(historyState(milliseconds, phase: phase));
  }

  Future<void> close() async {
    await player.close();
    await engine.dispose();
    await collection.dispose();
    await library.dispose();
  }
}
