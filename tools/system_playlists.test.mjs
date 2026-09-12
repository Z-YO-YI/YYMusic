import test from 'node:test';
import assert from 'node:assert/strict';
import { read } from './design_audit.mjs';

test('system song insertion borrows root edits with exact source and independent history confirmation', () => {
  const actions = read('lib/features/playlists/common/system_playlist_actions.dart');
  assert.match(actions, /type != SystemPlaylistType.queue/);
  assert.match(actions, /identical\(item, entry\)/);
  assert.match(actions, /intent == _intent && canOpenEntry/);
  const insertion = read('lib/features/playlists/common/system_queue_actions.dart');
  for (const token of ['queue.prepareInsertion(', 'queue.submitEdit(', 'QueueOperationFeedback(', 'sourcePermit!()', 'epoch == _queueEpoch']) assert(insertion.includes(token));
  assert.match(insertion, /request\?\.entry != null/);
  assert(!/saveQueue\(|recordHistory\(|setFavorite\(|AppDatabase|QueueController\(|PlaybackController\(/.test(insertion));
  const screen = read('lib/features/playlists/common/system_playlist_screen.dart');
  assert.match(screen, /_request = _captureRequest\(request.snapshot, request.entry\)/);
  assert.match(screen, /final identity = request.entry\?\.identity/);
  assert.match(screen, /if \(identity == null\)/);
  const panel = read('lib/features/playlists/common/system_playlist_management_panel.dart');
  for (const glyph of ['next', 'listPlus', 'heart']) assert(panel.includes(`YYGlyph.${glyph}`));
  assert.match(panel, /if \(snapshot.type == SystemPlaylistType.favorites\)/);
});

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
  assert.match(graph, /systemPlaylists = SystemPlaylistSessions\(\s*repository: this.collection,\s*playback: playback,?\s*\)/);
  assert.match(graph, /systemPlaylists.dispose\(\)/);
  assert(graph.indexOf('systemPlaylists.close,') < graph.indexOf('services.dispose'));
  const session = read('lib/features/playlists/common/system_playlist_controller.dart');
  assert.match(session, /final SystemPlaylistType type;/);
  assert.match(session, /watchSystemPlaylistChanges\(type\)/);
  assert.match(session, /readSystemPlaylistContent\(/);
  assert.match(session, /maxVisibleCount = 200/);
  assert.match(session, /revision == _readRevision/);
  assert.match(session, /!identical\(content, expected\)/);
  assert(!/readPlaylistContent\(|getTrack\(|saveQueue\(|setFavorite\(|recordHistory\(|PlaybackController\(|AppDatabase|\.addAll\(/.test(session));
});

test('system native surfaces reuse final glyphs, three layouts, and fixed enum routes', () => {
  const labels = read('lib/features/playlists/common/system_playlist_presentation.dart');
  for (const glyph of ['heart', 'history', 'queue']) assert(labels.includes(`YYGlyph.${glyph}`));
  for (const platform of ['phone', 'tablet', 'windows']) {
    assert.match(read(`lib/features/playlists/${platform}/${platform}_system_playlist_layout.dart`), /extends StatelessWidget/);
  }
  assert.match(read('lib/app/system_playlist_location.dart'), /SystemPlaylistType.values/);
  assert.match(read('lib/features/playlists/common/system_playlist_links.dart'), /YYPlaylistCard\(/);
  assert.match(read('lib/features/playlists/common/system_playlist_sections.dart'), /YYTrackTile\(/);
  assert.match(read('lib/app/yy_music_app.dart'), /systemPlaylists: ref.read\(dependencyGraphProvider\).systemPlaylists/);
});

test('system queue actions preserve exact IDs and guard own current-ID refresh separately', () => {
  const actions = read('lib/features/playlists/common/system_playlist_actions.dart');
  assert.match(actions, /e.id == entry.entryId && e.track == entry.reference/);
  assert.match(actions, /playEntry\(entry.entryId!, canPlay: current\)/);
  assert.match(actions, /playCatalogTrack\(entry.reference, canPlay: current\)/);
  assert.match(read('lib/features/playlists/common/system_playlist_controller.dart'), /type != SystemPlaylistType.queue\) _intent\+\+/);
  assert(!/saveQueue\(|setFavorite\(|recordHistory\(|deletePlaylist\(/.test(actions));
  assert.match(actions, /return _writer.clearHistory\(\)/);
  assert.match(actions, /return _writer.removeFavorite\(reference\)/);
});

test('system writes remain root-owned, typed and registered before dependencies', () => {
  const writer = read('lib/features/playlists/common/system_playlist_writer.dart');
  assert.match(writer, /setFavorite\(reference, favorite: false\)/);
  assert.match(writer, /identical\(history!\.collection, repository\)/);
  assert(writer.indexOf('_work = done.future;') < writer.indexOf('await action();'));
  assert(!/AppDatabase|deletePlaylist|saveQueue|File\(|Directory\(/.test(writer));
  const sessions = read('lib/features/playlists/common/system_playlist_sessions.dart');
  assert.match(sessions, /writer.dispose\(\)/);
  assert.match(sessions, /writer.close\(\)/);
});

test('native system management guards snapshots, confirmation and covered callbacks', () => {
  const screen = read('lib/features/playlists/common/system_playlist_screen.dart');
  assert.match(screen, /!identical\(_request, request\)/);
  assert.match(screen, /!identical\(controller.content, request.snapshot\)/);
  assert.match(screen, /ExcludeFocus\(/);
  assert.match(screen, /PopScope\(/);
  const panel = read('lib/features/playlists/common/system_playlist_management_panel.dart');
  for (const component of ['YYContextMenu', 'YYDialog', 'YYBottomSheet']) assert(panel.includes(`${component}(`));
  assert.match(panel, /label: '确认清除'/);
  assert.match(panel, /glyph: YYGlyph.heart/);
  assert(!/Icons\.|WebView|\.setFavorite\(|\.recordHistory\(/.test(panel));
});
