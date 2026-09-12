import test from 'node:test';
import assert from 'node:assert/strict';
import { read } from './design_audit.mjs';

test('shell queue delegates to existing navigation with revocable scope', () => {
  const root = read('lib/app/adaptive_root.dart');
  const actions = read('lib/features/player/common/shell_favorite_actions.dart');
  assert.match(root, /onOpenQueue: \(\) =>\s*navigation.openSystemPlaylist\(SystemPlaylistType.queue\)/);
  assert.match(actions, /_queueAction\(int generation\)[\s\S]*if \(!_canUseShellAction\(generation\)\) return;[\s\S]*_favoriteRouteChanged\(\);\s*open\(\);/);
  assert(!/QueueController\(|PlaybackController\(/.test(actions));
});
