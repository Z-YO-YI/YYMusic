import '../data/database/app_database.dart';
import '../data/database/database_connection.dart';
import '../data/repositories/drift_collection_repository.dart';
import '../data/repositories/drift_library_repository.dart';
import '../data/repositories/drift_lyrics_repository.dart';
import '../data/repositories/drift_music_source_repository.dart';
import '../domain/repositories/collection_repository.dart';
import '../domain/repositories/library_repository.dart';
import '../domain/repositories/lyrics_repository.dart';
import '../domain/repositories/music_source_repository.dart';
import '../platform/contracts/secure_credential_gateway.dart';
import '../platform/secure_credentials/android_secure_credential_gateway.dart';
import '../platform/secure_credentials/windows_secure_credential_gateway.dart';
import 'app_data_services.dart';
import 'layout_class.dart';

typedef AppDatabaseOpener = Future<AppDatabase> Function();
typedef AppDatabaseCloser = Future<void> Function(AppDatabase database);
typedef SecureCredentialGatewayFactory = SecureCredentialGateway Function(
  YYPlatform platform,
);

Future<AppDataServices> createProductionAppDataServices(
  YYPlatform platform, {
  AppDatabaseOpener openDatabase = openDefaultDatabase,
  AppDatabaseCloser closeDatabase = _closeAppDatabase,
  SecureCredentialGatewayFactory createCredentialGateway =
      _createPlatformCredentialGateway,
}) async {
  final database = await openDatabase();
  late final SecureCredentialGateway credentials;
  try {
    credentials = createCredentialGateway(platform);
  } catch (_) {
    await closeDatabase(database);
    rethrow;
  }
  return DatabaseAppDataServices.open(database, credentials: credentials);
}

Future<void> _closeAppDatabase(AppDatabase database) => database.close();

SecureCredentialGateway _createPlatformCredentialGateway(YYPlatform platform) =>
    switch (platform) {
      YYPlatform.android => AndroidSecureCredentialGateway(),
      YYPlatform.windows => WindowsSecureCredentialGateway(),
    };

final class DatabaseAppDataServices implements AppDataServices {
  static Future<DatabaseAppDataServices> open(
    AppDatabase database, {
    SecureCredentialGateway? credentials,
  }) async {
    final library = DriftLibraryRepository(database);
    final services = DatabaseAppDataServices._(
      database: database,
      library: library,
      collection: DriftCollectionRepository(database),
      lyrics: DriftLyricsRepository(database),
      musicSources: DriftMusicSourceRepository(database),
      credentials: credentials,
    );
    try {
      await library.initialize();
      return services;
    } catch (_) {
      await services.dispose();
      rethrow;
    }
  }

  DatabaseAppDataServices._({
    required this._database,
    required this._library,
    required this._collection,
    required this._lyrics,
    required this._musicSources,
    required this.credentials,
  });

  final AppDatabase _database;
  final DriftLibraryRepository _library;
  final DriftCollectionRepository _collection;
  final DriftLyricsRepository _lyrics;
  final DriftMusicSourceRepository _musicSources;
  bool _disposed = false;

  @override
  LibraryRepository get library => _library;

  @override
  CollectionRepository get collection => _collection;

  @override
  LyricsRepository get lyrics => _lyrics;

  @override
  MusicSourceRepository get musicSources => _musicSources;

  @override
  final SecureCredentialGateway? credentials;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await Future.wait([
        _library.dispose(),
        _collection.dispose(),
        _lyrics.dispose(),
        _musicSources.dispose(),
      ]);
    } finally {
      await _database.close();
    }
  }
}
