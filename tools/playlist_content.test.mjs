import test from 'node:test';
import assert from 'node:assert/strict';
import { read } from './design_audit.mjs';

test('playlist content reads a single bounded joined snapshot without writes or N+1 lookups', () => {
  const query = read('lib/data/repositories/drift_playlist_content.dart');
  assert.equal((query.match(/\.customSelect\(/g) ?? []).length, 1);
  assert.match(query, /page AS \([\s\S]*?LIMIT \? OFFSET \?[\s\S]*?LEFT JOIN tracks/);
  for (const column of ['source_type', 'source_id', 'track_id']) {
    assert(query.includes(`t.${column} = e.${column === 'track_id' ? column : `track_${column}`}`));
  }
  assert.match(query, /entries.putIfAbsent\(\s*id,/);
  assert.match(query, /playlist-system-content/);
  assert(!/getTrack\(|transaction\(|INSERT|UPDATE|DELETE|dart:io|HttpClient|watchTracks/.test(query));
  const repository = read('lib/data/repositories/drift_collection_repository.dart');
  const invalidation = repository.slice(repository.indexOf('Stream<void> watchPlaylistContentChanges'), repository.indexOf('Future<void> appendPlaylistEntry'));
  assert.match(invalidation, /tableUpdates\(/);
  for (const table of ['playlistRecords', 'playlistEntryRecords', 'trackRecords', 'trackArtistRecords', 'artistRecords']) {
    assert(invalidation.includes(`_database.${table}`));
  }
  assert(!/customSelect|\.watch\(|\.get\(/.test(invalidation));
});

test('root playlist projections borrow storage and drain explicit reads plus stream setup and cancellation', () => {
  const controller = read('lib/features/playlists/common/playlist_content_controller.dart');
  assert.match(controller, /pageSize = 20, maxVisibleCount = 200/);
  assert.match(controller, /await _repository!\.readPlaylistContent/);
  assert.match(controller, /revision == _readRevision/);
  assert.match(controller, /await old.cancel\(\)/);
  assert.match(controller, /await subscription.cancel\(\)/);
  assert.match(controller, /Future.wait<void>\(_pending\)[\s\S]*?whenComplete\(_onClosed\)/);
  assert.match(controller, /_notificationDepth != 0/);
  assert(!/AppDatabase|Drift|AudioEngine|PlaybackController|Fake|Fixture|WebView|watchTracks|replacePlaylistEntries|\.dispose\(\);.*repository/.test(controller));
  const graph = read('lib/app/dependency_graph.dart');
  assert.match(graph, /playlistContents = PlaylistContentSessions\(repository: this.collection\)/);
  assert.match(graph, /playlistContents.dispose\(\)/);
  assert.match(graph, /playlistContents.close,[\s\S]*?services.dispose/);
  const registry = read('lib/features/playlists/common/playlist_content_sessions.dart');
  assert.match(registry, /if \(_disposed\) throw StateError/);
  assert.match(registry, /\(\) => _sessions.remove\(session\)/);
});
