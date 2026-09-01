import '../models/lyrics.dart';
import '../models/track.dart';

abstract interface class LyricsRepository {
  Future<LyricsDocument?> getLyrics(TrackRef track);
  Future<void> saveLyrics(LyricsDocument document);
  Future<void> removeLyrics(TrackRef track);
}
