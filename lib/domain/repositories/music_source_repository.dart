import '../models/music_source.dart';

abstract interface class MusicSourceRepository {
  Stream<List<MusicSourceConfig>> watchSources();
  Future<MusicSourceConfig?> getSource(String id);
  Future<void> saveSource(MusicSourceConfig source);
  Future<void> deleteSource(String id);
}
