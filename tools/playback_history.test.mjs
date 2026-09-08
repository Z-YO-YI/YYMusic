import test from 'node:test';
import assert from 'node:assert/strict';
import { read } from './design_audit.mjs';

test('history belongs to the root, confirms clock progress, and drains before storage', () => {
  const root = read('lib/playback/playback_controller.dart');
  const history = read('lib/playback/playback_history_recorder.dart');
  assert.match(root, /history = PlaybackHistoryRecorder\(\s*collection: collection,/);
  assert.match(root, /_loadedEntryId == _state.queue.currentEntryId/);
  assert.match(root, /await history.close\(\)/);
  assert.match(history, /value.position > previous/);
  assert.match(history, /await previous/);
  assert(history.indexOf('_tail = done.future;') < history.indexOf('draft = capture();'));
  assert(!/AppDatabase|just_audio|BuildContext|AudioPlayer\(/.test(history));
});

test('history ID collision protection runs before the same-track deletion', () => {
  const store = read('lib/data/repositories/drift_collection_repository.dart').split('Future<void> recordHistory')[1];
  assert(store.indexOf('collection.history-id-conflict') < store.indexOf('_database.delete'));
  for (const key of ['sourceType.name', 'sourceId', 'trackId']) assert(store.includes(`entry.track.${key}`));
});

test('recent save failures reuse native feedback and the existing Home clear shares the writer', () => {
  const sections = read('lib/features/playlists/common/system_playlist_sections.dart');
  assert.match(sections, /SystemPlaylistType.recent &&\s*historyFailure != null/);
  assert.match(sections, /YYErrorBanner\(\s*title: '播放历史未保存'/);
  assert.match(sections, /if \(!canInteract\(\)\) return/);
  assert.match(read('lib/playback/playback_history_recorder.dart'), /!identical\(expected, failure\)/);
  const home = read('lib/features/home/common/home_controller.dart');
  assert.match(home, /await playback.history.clear\(\)/);
  assert(!/collection!?\.clearHistory\(/.test(home));
});
