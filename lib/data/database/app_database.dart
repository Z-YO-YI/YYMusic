import 'package:drift/drift.dart';

import 'app_database.steps.dart';
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      final nowMs = _clock().toUtc().millisecondsSinceEpoch;
      await into(schemaMigrationRecords).insert(
        SchemaMigrationRecordsCompanion.insert(
          version: Value(schemaVersion),
          appliedAtMs: nowMs,
          description: 'Initial YYMusic schema v2',
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
      if (from != 1 || to != 2) {
        throw StateError('Unsupported database migration $from -> $to');
      }
      await transaction(() async {
        await migrator.runMigrationSteps(
          from: from,
          to: to,
          steps: migrationSteps(
            from1To2: (step, schema) async {
              await step.addColumn(schema.tracks, schema.tracks.addedAtMs);
              await step.createIndex(schema.tracksByAdded);
            },
          ),
        );
        await into(schemaMigrationRecords).insert(
          SchemaMigrationRecordsCompanion.insert(
            version: const Value(2),
            appliedAtMs: _clock().toUtc().millisecondsSinceEpoch,
            description:
                'Record first catalog insertion time; legacy dates unknown',
          ),
        );
      });
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

DateTime _utcNow() => DateTime.now().toUtc();
