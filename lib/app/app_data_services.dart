import '../domain/repositories/collection_repository.dart';
import '../domain/repositories/library_repository.dart';
import '../domain/repositories/lyrics_repository.dart';
import '../domain/repositories/music_source_repository.dart';
import '../platform/contracts/secure_credential_gateway.dart';

/// One owned data scope for the app. Shells and widgets only see repository
/// contracts through [DependencyGraph], never Drift or platform plugin types.
abstract interface class AppDataServices {
  LibraryRepository get library;
  CollectionRepository get collection;
  LyricsRepository get lyrics;
  MusicSourceRepository get musicSources;
  SecureCredentialGateway? get credentials;

  Future<void> dispose();
}
