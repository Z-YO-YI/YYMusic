import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('Inspector two original settings buttons share the guarded existing modal callback', () => {
  const inspector = read('lib/design_system/yy_now_playing_inspector.dart');
  for (const [key, glyph] of [['inspector-settings-more', 'more'], ['inspector-settings-device', 'device']]) {
    assert.match(inspector, new RegExp(`${key}[\\s\\S]*?glyph: YYGlyph.${glyph},[\\s\\S]*?onPressed: onOpenSettings`));
  }
  const shell = read('lib/features/player/common/shell_player.dart');
  assert.match(shell, /YYNowPlayingInspector\(\s+onOpenSettings: _navigationAction\(\s+favoriteGeneration,\s+widget.onOpenSettings,/);
  const adaptive = read('lib/app/adaptive_root.dart');
  assert.equal((adaptive.match(/onOpenSettings: onOpenSettings/g) ?? []).length, 2);
  assert(!/PlaybackController|Timer|Repository|WebView/.test(inspector));
});
