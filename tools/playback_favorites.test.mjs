import test from 'node:test';
import assert from 'node:assert/strict';
import { read } from './design_audit.mjs';

test('retained shell favorite revokes route events and exact scope changes', () => {
  const shell = read('lib/features/player/common/shell_player.dart');
  for (const token of ['widget.routeChanges?.addListener(_favoriteRouteChanged)', 'widget.routeChanges?.removeListener(_favoriteRouteChanged)', 'oldWidget.scopeIdentity != widget.scopeIdentity', 'favoriteBusy: favorite?.busy ?? false', 'PlaybackFavoriteFeedback(']) assert(shell.includes(token));
  const actions = read('lib/features/player/common/shell_favorite_actions.dart');
  assert.match(actions, /generation != _favoriteGeneration/);
  assert.match(actions, /ModalRoute.of\(context\)\?\.isCurrent/);
  assert.match(actions, /final target = !expected.isFavorite!/);
  assert.match(actions, /canEdit: \(\) => _canFavorite\(generation\)/);
  const router = read('lib/app/app_router.dart');
  assert.equal((router.match(/routeChanges: _router.routerDelegate/g) ?? []).length, 5);
});

test('player favorite uses captured root intent and revocable page with shared feedback', () => {
  const screen = read('lib/features/player/common/player_screen.dart');
  const actions = read('lib/features/player/common/player_favorite_actions.dart');
  assert.match(screen, /widget.favorite\?\.addListener\(_onFavorite\)/);
  assert.match(screen, /widget.favorite\?\.removeListener\(_onFavorite\)/);
  assert.match(screen, /ModalRoute.of\(context\)\?\.isCurrent/);
  assert.match(screen, /PlaybackFavoriteFeedback\(/);
  assert.match(actions, /final expected = controller.state;/);
  assert.match(actions, /final target = !expected.isFavorite!;/);
  assert.match(actions, /canEdit: \(\) => _canInteract\(generation\)/);
  assert(!/Repository|AppDatabase|PlaybackController\(|watchFavorites\(/.test(actions));
});

test('lyrics favorite borrows root projection with captured page permission and separate busy', () => {
  const screen = read('lib/features/lyrics/common/lyrics_screen.dart');
  const actions = read('lib/features/lyrics/common/lyrics_favorite_actions.dart');
  assert.match(screen, /widget.favorite\?\.addListener\(_lyricsChanged\)/);
  assert.match(screen, /widget.favorite\?\.removeListener\(_lyricsChanged\)/);
  assert.match(screen, /ModalRoute.of\(context\)\?\.isCurrent/);
  assert.match(screen, /favoriteBusy: favorite\?\.busy \?\? false/);
  assert.match(actions, /final expected = controller.state;/);
  assert.match(actions, /final target = !expected.isFavorite!;/);
  assert.match(actions, /canEdit: \(\) => _canUse\(generation\)/);
  assert(!/Repository|AppDatabase|PlaybackController\(|watchFavorites\(/.test(actions));
  const feedback = read('lib/features/player/common/playback_favorite_feedback.dart');
  assert.match(feedback, /identical\(controller.failure, failure\)/);
  assert.match(feedback, /controller.retry\(failure, canEdit: permit\)/);
});

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
