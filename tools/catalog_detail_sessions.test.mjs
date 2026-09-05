import assert from 'node:assert/strict';
import test from 'node:test';
import { read, walk } from './design_audit.mjs';

test('detail sessions read scoped catalog contracts without storage, playback or fixture ownership', () => {
  for (const path of walk('lib/features/catalog_detail').filter(path => path.endsWith('.dart'))) {
    assert(!/AppDatabase|Drift|dart:io|AudioEngine|PlaybackController|Fake|Fixture|WebView|credentialRef|baseUrl|localPath|\.network\(|watchTracks\(|upsertTracks|setFavorite/.test(read(path)), path);
  }
  const controller = read('lib/features/catalog_detail/common/catalog_detail_controller.dart');
  for (const method of ['getAlbum', 'getArtist', 'browseTracks', 'browseAlbums']) {
    assert(controller.includes(`repository.${method}(`), method);
  }
  assert.match(controller, /offset: previous.rawCount/);
  assert.match(controller, /rawCount: previous.rawCount \+ raw.length/);
  assert.match(controller, /token.isCancelled/);
  assert.match(controller, /album.ref != reference/);
  assert.match(controller, /artist.ref != reference/);
  assert.match(controller, /track.sourceId == target.sourceId/);
  assert.match(controller, /track.albumId == reference.albumId/);
  const state = read('lib/features/catalog_detail/common/catalog_detail_state.dart');
  assert.match(state, /pageSize = 20/);
  assert.match(state, /maxRawCount = 200/);
  assert.match(state, /List.unmodifiable\(items\)/);
});

test('root retains closing detail sessions until real work drains before shared database close', () => {
  const graph = read('lib/app/dependency_graph.dart');
  assert.match(graph, /catalogDetails = CatalogDetailSessions\(repository: this.catalogBrowse\)/);
  assert.match(graph, /catalogDetails.dispose\(\)/);
  assert.match(graph, /catalogDetails.close,[\s\S]*?services.dispose/);
  const controller = read('lib/features/catalog_detail/common/catalog_detail_controller.dart');
  assert.match(controller, /Future.wait<void>\(_pending\)[\s\S]*?_onClosed\(\)/);
  const registry = read('lib/features/catalog_detail/common/catalog_detail_sessions.dart');
  assert.match(registry, /if \(_disposed\) throw StateError/);
  assert.match(registry, /\(\) => _sessions.remove\(session\)/);
});
