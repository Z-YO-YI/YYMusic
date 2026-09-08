import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const read = path => readFileSync(new URL(`../${path}`, import.meta.url), 'utf8');

test('playlist picker metadata query is literal, bounded and independent of media tables', () => {
  const source = read('lib/data/repositories/drift_collection_repository.dart');
  const selection = source.slice(source.indexOf('Future<PageResult<Playlist>> readCustomPlaylists'), source.indexOf('Future<void> createPlaylist'));
  assert.match(selection, /WHERE is_system = 0 AND instr\(lower\(name\), \?\) > 0/);
  assert.match(selection, /ORDER BY updated_at_ms DESC, playlist_id COLLATE BINARY ASC/);
  assert.match(selection, /Variable<int>\(page.limit \+ 1\)/);
  assert.match(selection, /Variable<int>\(page.offset\)/);
  assert.match(selection, /rows\s*\.take\(page.limit\)/);
  assert(!/JOIN|playlist_entries|tracks|credential|watchPlaylists/.test(selection));
  const controller = read('lib/features/playlists/common/playlist_add_controller.dart');
  assert.match(controller, /watchPlaylistContentChanges\(\)/);
  assert.match(controller, /await _repository!\.readCustomPlaylists/);
  assert.match(controller, /Future.wait<void>\(_pending\)/);
  assert.match(controller, /identical\(_snapshot, snapshot\)/);
  assert.match(controller, /_writer.addTrack\(id, track\)/);
  assert(!/watchPlaylists|AppDatabase|HttpClient|AudioEngine|PlaybackController|replacePlaylistEntries|savePlaylist/.test(controller));
});

test('root modal picker keeps sensitive Track data out of routing and owns safe closure boundaries', () => {
  const router = read('lib/app/app_router.dart');
  assert.match(router, /RawDialogRoute<void>/);
  assert.match(router, /RouteSettings\(name: 'playlist-add'\)/);
  assert.match(router, /transitionDuration: Duration.zero/);
  const dialog = read('lib/features/playlists/common/playlist_add_dialog.dart');
  assert.match(dialog, /final TrackRef track;/);
  assert.match(dialog, /mounted &&[\s\S]*?!_closing/);
  assert.match(dialog, /_closing = true/);
  assert.match(dialog, /PlaylistNameQuery\(input.text\)/);
  assert.match(dialog, /controller.close\(\)/);
  assert(!/WebView|Material|Cupertino|localPath|contentUri|HttpClient|createPlaylist/.test(dialog));
  const graph = read('lib/app/dependency_graph.dart');
  assert.match(graph, /playlistAdds = PlaylistAddSessions\([\s\S]*?writer: playlists/);
  assert.match(graph, /playlistAdds.dispose\(\)/);
  assert.match(graph, /playlistAdds.close,[\s\S]*?services.dispose/);
});
