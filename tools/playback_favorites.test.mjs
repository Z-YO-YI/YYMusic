import test from 'node:test';
import assert from 'node:assert/strict';
import { read } from './design_audit.mjs';

test('current favorite root borrows playback and collection with explicit start and shutdown barrier', () => {
  const graph = read('lib/app/dependency_graph.dart');
  assert.match(graph, /playbackFavorite = PlaybackFavoriteController\(/);
  assert.match(graph, /await playback.initialize\(\);\s*if \(_closeFuture == null\) playbackFavorite.start\(\)/);
  assert(graph.indexOf('playbackFavorite.dispose();') < graph.indexOf('playback.dispose();'));
  assert(graph.indexOf('playbackFavorite.close,') < graph.indexOf('services.dispose'));
  const controller = read('lib/playback/playback_favorite_controller.dart');
  assert.match(controller, /watchFavorites\(\).listen\(/);
  assert.match(controller, /identical\(state.queue, _playback.state.queue\)/);
  assert.match(controller, /Set.unmodifiable/);
  assert.match(controller, /if \(!_started && state.reference != null\) retryRead\(\)/);
  assert.match(controller, /Future.wait<void>\(_pending\)/);
  assert(!/AppDatabase|AudioEngine\(|PlaybackController\(|saveQueue\(|recordHistory\(|\.toggleFavorite\(/.test(controller));
});

test('favorite commands preserve explicit target and exact failed projection identity', () => {
  const actions = read('lib/playback/playback_favorite_actions.dart');
  for (const token of ['identical(state, expected)', 'identical(failure, expected)', 'favorite: expected.favorite!', 'canSet(expected.expected)', '_busy = true;', 'PlaybackFavoriteEditResult.cancelled']) assert(actions.includes(token));
  assert.match(actions, /expected.reference!,\s*favorite: favorite/);
  assert(!/saveQueue\(|recordHistory\(|\.play\(|\.stop\(|_favorites\.(add|remove)/.test(actions));
  const state = read('lib/playback/playback_favorite_state.dart');
  assert.match(state, /final bool\? isFavorite;/);
  assert.match(state, /final PlaybackFavoriteState expected;/);
});
