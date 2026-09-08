import test from 'node:test';
import assert from 'node:assert/strict';
import { read } from './design_audit.mjs';

test('complete playback plan is a single bound lightweight read without a window cap or N+1', () => {
  const sql = read('lib/data/repositories/drift_playlist_playback_plan.dart');
  assert.equal((sql.match(/\.customSelect\(/g) ?? []).length, 1);
  assert.match(sql, /WHERE p.playlist_id = \?/);
  assert.match(sql, /t.source_type = e.track_source_type/);
  assert.match(sql, /t.source_id = e.track_source_id AND t.track_id = e.track_id/);
  assert.match(sql, /ORDER BY e.position, e.entry_id/);
  assert(!/\bLIMIT\b|\bOFFSET\b|track_artists|getTrack\(|local_path|stream_url/.test(sql));
  const model = read('lib/domain/models/playlist_playback_plan.dart');
  assert.match(model, /List.unmodifiable\(entries\)/);
  assert.match(model, /entry.position != i \|\| !ids.add\(entry.id\)/);
});

test('whole-playlist UI uses one root selection command and explicit queue replacement messaging', () => {
  const actions = read('lib/features/playlists/common/playlist_content_actions.dart');
  assert.match(actions, /!identical\(content, expected\)/);
  assert.match(actions, /readPlaylistPlaybackPlan\(playlistId\)/);
  assert.match(actions, /\.where\(\(e\) => e.isAvailable\)/);
  assert.match(actions, /playCatalogSelection\(/);
  assert(!/replaceQueue\(|setShuffleEnabled\(|saveQueue\(|getPlaylistEntries\(/.test(actions));
  const command = read('lib/playback/catalog_selection_playback.dart');
  assert.equal((command.match(/await _schedule\(/g) ?? []).length, 1);
  assert.equal((command.match(/await _commitQueue\(/g) ?? []).length, 1);
  assert(command.indexOf('Invalid shuffle index') < command.indexOf('await _commitQueue'));
  assert.match(command, /canCommit: allowed/);
  const ui = read('lib/features/playlists/common/playlist_content_sections.dart');
  assert.match(ui, /播放整份歌单的可用歌曲，替换当前队列/);
  assert.match(ui, /glyph: YYGlyph.shuffle/);
  assert(!/播放全部与随机播放尚未接入/.test(ui));
});
