part of 'drift_library_repository.dart';

extension _LocalLibraryQueries on DriftLibraryRepository {
  Future<LocalLibraryOverview> _readLocalOverview(
    PageRequest page,
    SearchCancellation? cancellation,
  ) {
    _searchCheckpoint(cancellation);
    return _guard('local-overview', () async {
      // Every dynamic SQL fragment is a closed enum, never user input. Joining
      // the single statistics row preserves totals even beyond the final page.
      final availabilityCounts = TrackAvailability.values
          .map(
            (state) =>
                "COUNT(CASE WHEN availability = '${state.name}' THEN 1 END) AS count_${state.name}",
          )
          .join(', ');
      final rows = await _database
          .customSelect(
            '''
        WITH track_stats AS (
          SELECT $availabilityCounts,
            COALESCE(SUM(duration_ms), 0) AS total_duration_ms
          FROM tracks WHERE source_type = 'local'
        ), folder_stats AS (
          SELECT COUNT(*) AS folder_count,
            COUNT(CASE WHEN enabled = 1 THEN 1 END) AS enabled_count
          FROM local_folders
        ), folder_page AS (
          SELECT folder_id, display_name, platform, enabled, last_scanned_at_ms
          FROM local_folders ORDER BY lower(display_name), display_name, folder_id
          LIMIT ? OFFSET ?
        )
        SELECT track_stats.*, folder_stats.*, folder_page.*
        FROM track_stats CROSS JOIN folder_stats LEFT JOIN folder_page ON 1 = 1
        ORDER BY lower(folder_page.display_name), folder_page.display_name,
          folder_page.folder_id
      ''',
            variables: [Variable(page.limit), Variable(page.offset)],
          )
          .get();
      _searchCheckpoint(cancellation);
      final stats = rows.first;
      final folders = <LocalFolderSummary>[];
      for (final row in rows) {
        final id = row.readNullable<String>('folder_id');
        if (id == null) continue;
        final scannedAt = row.readNullable<int>('last_scanned_at_ms');
        folders.add(
          LocalFolderSummary(
            id: id,
            displayName: row.read<String>('display_name'),
            platform: switch (row.read<String>('platform')) {
              'windows' => LocalFolderPlatform.windows,
              'android' => LocalFolderPlatform.android,
              _ => LocalFolderPlatform.unknown,
            },
            enabled: row.read<int>('enabled') == 1,
            lastScannedAt: scannedAt == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(scannedAt, isUtc: true),
          ),
        );
      }
      final result = LocalLibraryOverview(
        tracks: LocalTrackSummary(
          counts: {
            for (final state in TrackAvailability.values)
              state: stats.read<int>('count_${state.name}'),
          },
          totalDuration: Duration(
            milliseconds: stats.read<int>('total_duration_ms'),
          ),
        ),
        folderCount: stats.read<int>('folder_count'),
        enabledFolderCount: stats.read<int>('enabled_count'),
        page: page,
        folders: folders,
      );
      _searchCheckpoint(cancellation);
      return result;
    });
  }

  Stream<void> _watchLocalChanges() {
    _requireReady();
    return _database
        .tableUpdates(
          TableUpdateQuery.onAllTables([
            _database.trackRecords,
            _database.localFolderRecords,
          ]),
        )
        .map<void>((_) {})
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (Object error, StackTrace stackTrace, sink) {
              sink.addError(_failureFor(error, 'watch-local'), stackTrace);
            },
          ),
        );
  }
}
