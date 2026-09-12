import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('all production shell frames capture URI and reuse the guarded root sleep modal', () => {
  const router = read('lib/app/app_router.dart');
  assert.equal((router.match(/AdaptiveRoot\(/g) ?? []).length, 5);
  assert.equal((router.match(/onOpenSettings: _shellSleepAction\(\s+playbackPresenter,\s+platform,\s+state.uri,/g) ?? []).length, 5);
  const shell = read('lib/features/player/common/shell_player.dart');
  assert.match(shell, /onOpenSettings: _navigationAction\(\s*favoriteGeneration,\s*widget.onOpenSettings,?\s*\)/);
  assert(shell.includes('oldWidget.onOpenSettings != widget.onOpenSettings'));
  const modal = read('lib/app/sleep_settings_route.dart');
  for (const required of ['_activeLocation != owner', '_activeLocation == owner',
    '_sleepOwnerLocation = owner', 'navigator.removeRoute(dialog)']) assert(modal.includes(required), required);
  assert(!/PlaybackController\(|\bTimer\b|Repository|WebView/.test(modal));
  const surface = read('lib/design_system/yy_player_surface.dart');
  assert.match(surface, /id: 'desktop-settings',[\s\S]*?glyph: YYGlyph.device/);
});
