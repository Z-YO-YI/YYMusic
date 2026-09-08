import test from 'node:test';
import assert from 'node:assert/strict';
import { read } from './design_audit.mjs';

test('interactive entries have atomic identity and anchor contracts, not stale whole-list replacement', () => {
  const contract = read('lib/domain/repositories/collection_repository.dart');
  for (const command of ['appendPlaylistEntry', 'removePlaylistEntry', 'movePlaylistEntry']) {
    assert.match(contract, new RegExp(`Future<void> ${command}\\(`));
  }
  assert.match(contract, /String\? beforeEntryId/);
  const commands = read('lib/data/repositories/drift_playlist_entry_commands.dart');
  assert.equal((commands.match(/_database.transaction/g) ?? []).length, 3);
  assert(!/replacePlaylistEntries|insertOnConflictUpdate|savePlaylist\(/.test(commands));
  assert.match(commands, /playlist-entry-id-exists/);
  assert.match(commands, /playlist-system-entries/);
  assert.match(commands, /COUNT\(\*\) AS n, MAX\(position\)/);
  const bulkUpdates = commands.match(/UPDATE playlist_entries[^']+/g);
  assert.equal(bulkUpdates.length, 2);
  for (const sql of bulkUpdates) assert.match(sql, /WHERE playlist_id = \? AND position BETWEEN \? AND \?/);
  assert(!/queue|favorite|history|sourceRecords|dart:io|HttpClient/.test(commands));
});

test('root entry commands use existing pending lifecycle without a list cache or audio side effects', () => {
  const controller = read('lib/features/playlists/common/playlist_controller.dart');
  const entries = controller.slice(controller.indexOf('Future<PlaylistCommandResult> addTrack'), controller.indexOf('Future<PlaylistCommandResult> _run'));
  assert.equal((entries.match(/_run\(/g) ?? []).length, 3);
  assert.match(entries, /_entryIdFactory\(\)/);
  assert.match(controller, /_randomId\('playlist-entry'\)/);
  assert.match(controller, /collection-repository.playlist-system-entries/);
  assert(!/StreamSubscription|watchPlaylists|getPlaylistEntries|replacePlaylistEntries|AudioEngine|PlaybackController|AppDatabase/.test(controller));
});
