import test from 'node:test';
import assert from 'node:assert/strict';
import { read } from './design_audit.mjs';

test('system playlist reads select enum-only sources and bind pages before artist fan-out', () => {
  const query = read('lib/data/repositories/drift_system_playlist_content.dart');
  assert.equal((query.match(/\.customSelect\(/g) ?? []).length, 1);
  assert.match(query, /switch \(type\)/);
  assert.match(query, /FROM play_history ORDER BY started_at_ms DESC, history_id LIMIT 20/);
  assert.match(query, /ORDER BY position LIMIT \? OFFSET \?/);
  assert(query.indexOf('LIMIT ? OFFSET ?') < query.indexOf('LEFT JOIN track_artists'));
  assert.match(query, /t.source_type = e.track_source_type/);
  assert.match(query, /state.current_id IS NULL OR EXISTS/);
  assert(!/getTrack\(|watchFavorites\(|watchHistory\(|loadQueue\(|FROM playlists|playlist_entries|\.transaction\(/.test(query));
});

test('system views are immutable separate models with scoped query-free invalidation', () => {
  const model = read('lib/domain/models/system_playlist_content.dart');
  assert.match(model, /List.unmodifiable\(entries\)/);
  assert.match(model, /entryId \?\? reference/);
  assert.match(model, /totalCount > 20/);
  assert(!/final Playlist playlist|\bPlaylistEntry\(|extends Playlist/.test(model));
  const watcher = read('lib/data/repositories/drift_system_playlist_content.dart').split('Stream<void> _watchSystemChanges')[1];
  assert.match(watcher, /TableUpdateQuery.onAllTables/);
  for (const type of ['favorites', 'recent', 'queue']) assert(watcher.includes(`type == SystemPlaylistType.${type}`));
  assert(!/\.get\(|\.watch\(|readSystem|playlistRecords/.test(watcher));
});

test('system sessions borrow the root repository and drain before storage without mutation APIs', () => {
  const graph = read('lib/app/dependency_graph.dart');
  assert.match(graph, /systemPlaylists = SystemPlaylistSessions\(repository: this.collection\)/);
  assert.match(graph, /systemPlaylists.dispose\(\)/);
  assert(graph.indexOf('systemPlaylists.close,') < graph.indexOf('services.dispose'));
  const session = read('lib/features/playlists/common/system_playlist_controller.dart');
  assert.match(session, /final SystemPlaylistType type;/);
  assert.match(session, /watchSystemPlaylistChanges\(type\)/);
  assert.match(session, /readSystemPlaylistContent\(/);
  assert.match(session, /maxVisibleCount = 200/);
  assert.match(session, /revision == _readRevision/);
  assert.match(session, /!identical\(content, expected\)/);
  assert(!/readPlaylistContent\(|getTrack\(|saveQueue\(|setFavorite\(|recordHistory\(|PlaybackController|AppDatabase|\.addAll\(/.test(session));
});
