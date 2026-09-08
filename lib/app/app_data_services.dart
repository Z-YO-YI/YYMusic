import '../domain/repositories/appearance_settings_repository.dart';
import '../domain/repositories/catalog_browse_repository.dart';
import '../domain/repositories/catalog_search_repository.dart';
import '../domain/repositories/collection_repository.dart';
import '../domain/repositories/library_repository.dart';
import '../domain/repositories/local_library_repository.dart';
import '../domain/repositories/lyrics_repository.dart';
import '../domain/repositories/music_source_repository.dart';
import '../domain/repositories/search_history_repository.dart';
import '../platform/contracts/secure_credential_gateway.dart';

/// One owned data scope for the app. Shells and widgets only see repository
/// contracts through [DependencyGraph], never Drift or platform plugin types.
abstract interface class AppDataServices {
  AppearanceSettingsRepository get appearanceSettings;
  LibraryRepository get library;
  LocalLibraryRepository get localLibrary;
  CatalogSearchRepository get catalogSearch;
  CatalogBrowseRepository get catalogBrowse;
  SearchHistoryRepository get searchHistory;
  CollectionRepository get collection;
  LyricsRepository get lyrics;
  MusicSourceRepository get musicSources;
  SecureCredentialGateway? get credentials;

  Future<void> dispose();
}
