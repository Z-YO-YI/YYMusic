import test from 'node:test';
import assert from 'node:assert/strict';
import { read } from './design_audit.mjs';

test('phone and desktop metadata navigation uses the revocable shell scope', () => {
  const shell = read('lib/features/player/common/shell_player.dart');
  assert.equal((shell.match(/onOpen: _navigationAction\(favoriteGeneration, widget.onOpen\)/g) ?? []).length, 2);
  assert.equal((shell.match(/_navigationAction\(favoriteGeneration, widget.onOpenLyrics\)/g) ?? []).length, 3);
  assert(!/onOpen: widget.onOpen|onOpenLyrics: presenter.queueCount > 0 \? widget.onOpenLyrics/.test(shell));
});

test('inspector borrows root navigation and the same revocable route scope', () => {
  const root = read('lib/app/adaptive_root.dart');
  assert.match(root, /inspector: true,[\s\S]*routeChanges: routeChanges,[\s\S]*scopeIdentity:/);
  const shell = read('lib/features/player/common/shell_player.dart');
  assert.match(shell, /return YYNowPlayingInspector\([\s\S]*onOpenFullscreen: _navigationAction\([\s\S]*onOpenLyrics: presenter.queueCount > 0/);
  const inspector = read('lib/design_system/yy_now_playing_inspector.dart');
  assert.match(inspector, /onPressed: onOpenFullscreen/);
  assert.match(inspector, /onPressed: onOpenLyrics/);
});

test('shell queue delegates to existing navigation with revocable scope', () => {
  const root = read('lib/app/adaptive_root.dart');
  const actions = read('lib/features/player/common/shell_favorite_actions.dart');
  assert.match(root, /onOpenQueue: \(\) =>\s*navigation.openSystemPlaylist\(SystemPlaylistType.queue\)/);
  assert.match(actions, /_queueAction\(int generation\)[\s\S]*if \(!_canUseShellAction\(generation\)\) return;[\s\S]*_favoriteRouteChanged\(\);\s*open\(\);/);
  assert(!/QueueController\(|PlaybackController\(/.test(actions));
});

test('shell fullscreen requests the existing native session through all five frames', () => {
  const router = read('lib/app/app_router.dart');
  assert.equal((router.match(/onOpenFullscreen: openFullscreenPlayer/g) ?? []).length, 5);
  assert.match(router, /void openFullscreenPlayer\(\) \{\s*fullscreen\?\.enterOnNextPlayer\(\);\s*openPlayer\(\);/);
  const shell = read('lib/features/player/common/shell_player.dart');
  assert.match(shell, /onOpenFullscreen: _navigationAction\(\s*favoriteGeneration,\s*widget.onOpenFullscreen,/);
  assert(!/FullscreenPresenter\(|NativeFullscreenGateway\(/.test(shell));
});
