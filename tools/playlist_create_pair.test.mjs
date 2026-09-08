import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const read = path => readFileSync(new URL(`../${path}`, import.meta.url), 'utf8');

test('create with entry is one SQLite transaction and a single root writer command', () => {
  const source = read('lib/data/repositories/drift_playlist_entry_commands.dart');
  const pair = source.slice(source.indexOf('Future<void> _createWithEntry'), source.indexOf('Future<void> _appendEntry'));
  assert.match(pair, /_database.transaction\(/);
  assert.match(pair, /await _insertCustomPlaylist\(playlist, name\)/);
  assert.match(pair, /playlist-entry-id-exists/);
  assert.match(pair, /position: 0/);
  assert(!/appendPlaylistEntry|savePlaylist|replacePlaylistEntries|HttpClient|AudioEngine/.test(pair));
  const writer = read('lib/features/playlists/common/playlist_controller.dart');
  const command = writer.slice(writer.indexOf('Future<PlaylistCommandResult> createPlaylistWithTrack'), writer.indexOf('Future<PlaylistCommandResult> renamePlaylist'));
  assert.match(command, /await collection!\.createPlaylistWithEntry\(/);
  assert.match(command, /entryCommand: true/);
  assert.equal((command.match(/_clock\(\)/g) ?? []).length, 1);
  assert(!/collection!\.createPlaylist\(|appendPlaylistEntry/.test(command));
});

test('picker owns independent native create draft and uses its drainable accepted-write path', () => {
  const picker = read('lib/features/playlists/common/playlist_add_controller.dart');
  assert.match(picker, /_writer.createPlaylistWithTrack\(name, track\)/);
  assert.match(picker, /result.complete\(action\(\)\)/);
  assert.match(picker, /_created = created/);
  const ui = read('lib/features/playlists/common/playlist_add_dialog.dart');
  assert.match(ui, /final nameInput = TextEditingController\(\)/);
  assert.match(ui, /nameInput.value != draft/);
  assert.match(ui, /controller.createAndAdd\(draft.text\)/);
  assert.match(ui, /nameInput.dispose\(\)/);
  assert.match(ui, /YYGlyph.plus/);
  assert(!/createPlaylistWithEntry|AppDatabase|WebView|Material|Cupertino/.test(ui));
});
