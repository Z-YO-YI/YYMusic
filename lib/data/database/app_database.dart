import 'package:drift/drift.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    TrackRecords,
    AlbumRecords,
    ArtistRecords,
    TrackArtistRecords,
    AlbumArtistRecords,
    PlaylistRecords,
    PlaylistEntryRecords,
    FavoriteRecords,
    PlayHistoryRecords,
    QueueEntryRecords,
    QueueStateRecords,
    MusicSourceRecords,
    LocalFolderRecords,
    LyricsCacheRecords,
    SearchHistoryRecords,
    AppSettingRecords,
    SchemaMigrationRecords,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor, {DateTime Function()? clock})
    : _clock = clock ?? _utcNow;

  final DateTime Function() _clock;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      final nowMs = _clock().toUtc().millisecondsSinceEpoch;
      await into(schemaMigrationRecords).insert(
        SchemaMigrationRecordsCompanion.insert(
          version: const Value(1),
          appliedAtMs: nowMs,
          description: 'Initial YYMusic schema',
        ),
      );
      await into(queueStateRecords).insert(
        QueueStateRecordsCompanion.insert(
          singletonId: const Value(1),
          updatedAtMs: nowMs,
        ),
      );
    },
    onUpgrade: (migrator, from, to) async {
      throw StateError('Unsupported database migration $from -> $to');
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

DateTime _utcNow() => DateTime.now().toUtc();
