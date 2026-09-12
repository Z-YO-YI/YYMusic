import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/lyrics.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/domain/repositories/lyrics_repository.dart';

import 'fake_audio_engine.dart';
import 'fake_domain_repositories.dart';
import 'fake_playback_dependencies.dart';

final lyricsTracks = [
  for (final source in ['one', 'two', 'three'])
    Track(
      id: 'same-id',
      sourceId: source,
      sourceType: MusicSourceType.rest,
      title: 'Test-only same title',
      artists: const ['Test'],
      duration: const Duration(minutes: 3),
    ),
];

List<QueueEntry> lyricsEntries() => [
  for (final (index, track) in lyricsTracks.indexed)
    QueueEntry(
      id: 'entry-$index',
      track: track.ref,
      position: index,
      addedAt: DateTime.utc(2026),
    ),
];

LyricsDocument timedLyrics(TrackRef track, {Duration offset = Duration.zero}) =>
    LyricsDocument(
      track: track,
      kind: LyricsKind.synchronized,
      language: 'en',
      translationLanguage: 'zh',
      offset: offset,
      lines: [
        for (var index = 0; index < 3; index++)
          LyricsLine(
            start: Duration(seconds: 10 + index * 10),
            end: Duration(seconds: 20 + index * 10),
            text: 'Test line $index',
            translation: '测试行 $index',
          ),
      ],
    );

final class LyricsProbe implements LyricsRepository {
  final documents = <TrackRef, LyricsDocument>{};
  final reads = <TrackRef>[];
  Future<LyricsDocument?> Function(TrackRef)? onGet;
  int inFlight = 0;
  int maximumInFlight = 0;

  @override
  Future<LyricsDocument?> getLyrics(TrackRef track) async {
    reads.add(track);
    inFlight++;
    if (inFlight > maximumInFlight) maximumInFlight = inFlight;
    try {
      return onGet == null ? documents[track] : await onGet!(track);
    } finally {
      inFlight--;
    }
  }

  @override
  Future<void> saveLyrics(LyricsDocument document) async {
    documents[document.track] = document;
  }

  @override
  Future<void> removeLyrics(TrackRef track) async {
    documents.remove(track);
  }
}

final class LyricsFixture {
  LyricsFixture({DateTime Function()? clock}) {
    // One import batch has one timestamp. Calling the wall clock per track
    // makes recent ordering depend on the host clock's resolution, changing
    // which same-title row is highlighted in production-page goldens.
    final importedAt = (clock ?? DateTime.now)().toUtc();
    for (final track in lyricsTracks) {
      repository.documents[track.ref] = timedLyrics(track.ref);
    }
    graph = DependencyGraph(
      audioEngine: engine,
      playbackSourceResolver: FakePlaybackSourceResolver(),
      library: FakeLibraryRepository(
        tracks: lyricsTracks,
        clock: () => importedAt,
      ),
      lyrics: repository,
    );
  }

  final engine = FakeAudioEngine();
  final repository = LyricsProbe();
  late final DependencyGraph graph;

  Future<void> initialize() async {
    await graph.initialize();
    await graph.queue.replace(lyricsEntries(), currentEntryId: 'entry-0');
    await graph.playback.play();
  }
}

Future<void> flushLyrics() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
