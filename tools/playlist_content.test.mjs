import test from 'node:test';
import assert from 'node:assert/strict';
import { read } from './design_audit.mjs';

test('custom playlist queue insertion captures exact window and entry, not metadata or playlist mutation', () => {
  const actions = read('lib/features/playlists/common/playlist_content_actions.dart');
  for (const token of ['queueSourcePermit(', 'identical(content, expected)', 'expected.entries.any((item) => identical(item, entry))', 'intent == _intent && available()']) assert(actions.includes(token));
  const screen = read('lib/features/playlists/common/playlist_content_screen.dart');
  for (const token of ['_queueEpoch++', '_captureMenu(request.id, request.snapshot)', 'widget.queue?.removeListener(_queueChanged)', 'request.sourcePermit?.call()']) assert(screen.includes(token));
  assert.match(screen, /void dispose\(\)[\s\S]*?_menu = null;[\s\S]*?_returnFocus = null;/);
  const insert = read('lib/features/playlists/common/playlist_queue_actions.dart');
  for (const token of ['queue.prepareInsertion(', 'entry.entry.track', 'queue.submitEdit(', 'pagePermit() && sourcePermit!()', 'QueueOperationFeedback(', 'identical(noticeIdentity, _noticeIdentity)']) assert(insert.includes(token));
  assert(!/QueueController\(|PlaybackController\(|Repository|removeEntry|moveEntry|replacePlaylistEntries|WebView/.test(insert));
  const menu = read('lib/features/playlists/common/playlist_entry_menu.dart');
  for (const token of ["id: 'next'", "id: 'queue'", 'YYGlyph.next', 'YYGlyph.listPlus', 'enabled: canInsert', '队列与歌单独立']) assert(menu.includes(token));
});

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
  assert(!/AppDatabase|Drift|AudioEngine|PlaybackController\(|Fake|Fixture|WebView|watchTracks|replacePlaylistEntries|\.dispose\(\);.*repository/.test(controller));
  const graph = read('lib/app/dependency_graph.dart');
  assert.match(graph, /playlistContents = PlaylistContentSessions\(\s*repository: this.collection,\s*playback: playback,\s*writer: playlists,/);
  assert.match(graph, /playlistContents.dispose\(\)/);
  assert.match(graph, /playlistContents.close,[\s\S]*?services.dispose/);
  const registry = read('lib/features/playlists/common/playlist_content_sessions.dart');
  assert.match(registry, /if \(_disposed\) throw StateError/);
  assert.match(registry, /\(\) => _sessions.remove\(session\)/);
});

test('playlist route and layouts reuse one native session while stale menu callbacks fail closed', () => {
  const router = read('lib/app/app_router.dart');
  assert.match(router, /parsePlaylistLocation\(state.uri\)/);
  assert.match(router, /PlaylistContentScreen\([\s\S]*?frame: \(child\) => AdaptiveRoot/);
  const screen = read('lib/features/playlists/common/playlist_content_screen.dart');
  assert.match(screen, /widget.sessions.open\(widget.playlistId\)/);
  assert.match(screen, /identical\(_menu, request\)/);
  assert.match(screen, /identical\(controller.content, request.snapshot\)/);
  assert.match(screen, /controller.setActive\(_active\)/);
  assert.match(screen, /controller.close\(\)/);
  for (const platform of ['phone', 'tablet', 'windows']) {
    const layout = read(`lib/features/playlists/${platform}/${platform}_playlist_content_layout.dart`);
    assert.match(layout, /PageStorageKey\('playlist-scroll'\)/);
    assert(!/sessions.open|\.start\(|\.refresh\(|playCatalogTrack|AppDatabase|WebView|Material/.test(layout));
  }
});

test('playlist actions borrow root writer and player with registered work, identity anchors and retained safe failure', () => {
  const actions = read('lib/features/playlists/common/playlist_content_actions.dart');
  assert.match(actions, /_playback!\.playCatalogTrack/);
  assert.match(actions, /canPlay: \(\) => !_disposed && _active && intent == _intent/);
  assert.match(actions, /index \+ 2 < items.length \|\| !content!\.hasMore/);
  assert.match(actions, /_writer!\.moveEntry\(playlistId, id, beforeEntryId: anchor\)/);
  assert(actions.indexOf('final work = _track', actions.indexOf('Future<void> _writeEntry')) < actions.indexOf('result.complete(invoke())'));
  assert(!/replacePlaylistEntries|savePlaylist|AudioEngine\(|PlaybackController\(|AppDatabase|HttpClient/.test(actions));
  const host = read('lib/features/playlists/common/playlist_editor_host.dart');
  assert.match(host, /_lateFailure \?\? widget.controller.entryFailure/);
  assert.match(host, /widget.controller.dismissEntryFailure\(\)/);
});
