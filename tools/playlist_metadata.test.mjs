import test from 'node:test';
import assert from 'node:assert/strict';
import { read } from './design_audit.mjs';

test('playlist metadata edits use distinct atomic contracts, not read-then-upsert commands', () => {
  const contract = read('lib/domain/repositories/collection_repository.dart');
  assert.match(contract, /Future<void> createPlaylist\(Playlist playlist\)/);
  assert.match(contract, /Future<void> renamePlaylist\(String id, String name\)/);
  const repository = read('lib/data/repositories/drift_collection_repository.dart');
  const create = repository.slice(repository.indexOf('Future<void> createPlaylist'), repository.indexOf('Future<void> renamePlaylist'));
  const rename = repository.slice(repository.indexOf('Future<void> renamePlaylist'), repository.indexOf('Future<void> savePlaylist'));
  for (const method of [create, rename]) assert.match(method, /_database.transaction/);
  assert.match(create, /playlist-id-exists/);
  assert.match(create, /playlist-system-create/);
  assert(!/insertOnConflictUpdate/.test(create));
  assert.match(rename, /playlist-system-rename/);
  assert.match(rename, /DomainFailureCode.notFound/);
  assert.match(rename, /now < row.updatedAtMs \? row.updatedAtMs : now/);
  assert(!/\.insert|\.delete|createdAtMs:|description:/.test(rename));
});

test('root playlist writer borrows storage, remains lazy and drains registered work before database close', () => {
  const controller = read('lib/features/playlists/common/playlist_controller.dart');
  assert(!/AppDatabase|Drift|dart:io|watchPlaylists|getPlaylist\(|savePlaylist\(|AudioEngine|WebView|Fake|Fixture/.test(controller));
  assert.match(controller, /PlaylistName.normalize\(name\)/);
  assert.match(controller, /Random.secure\(\)/);
  assert.match(controller, /List.generate\(\s*16/);
  assert.match(controller, /_pending = Future<PlaylistCommandResult>/);
  assert.match(controller, /_closeFuture = _pending\?\.then/);
  assert.match(controller, /if \(!isAvailable\)/);
  const graph = read('lib/app/dependency_graph.dart');
  assert.match(graph, /playlists = PlaylistController\(collection: this.collection\)/);
  assert.match(graph, /playlists.dispose\(\)/);
  const writerClose = graph.indexOf('playlists.close,');
  const storageClose = graph.indexOf('services.dispose');
  assert(writerClose >= 0 && storageClose > writerClose);
});
