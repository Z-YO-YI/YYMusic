import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('player settings use the original more glyph and root-owned exact modal route', () => {
  const player = read('lib/features/player/common/player_screen.dart');
  assert.match(player, /player-page-settings[\s\S]*?glyph: YYGlyph.more/);
  assert.match(player, /onPressed: action\(true, widget.onOpenSettings!\)/);
  const router = read('lib/app/app_router.dart');
  assert.match(router, /onOpenSettings: \(\) => _openSleepSettings\(\s+playbackPresenter,\s+platform,\s+owner: AppRoute.player,/);
  assert.match(router, /_sleepDialog != null &&\s+\(_activePath != _sleepOwnerPath \|\|\s+_activeLocation != _sleepOwnerLocation\)/);
  const modal = read('lib/app/sleep_settings_route.dart');
  for (const required of ['RawDialogRoute<void>', 'identical(_sleepDialog, dialog)',
    'dialog.isCurrent', '_activePath == ownerPath', 'addPostFrameCallback',
    'navigator.removeRoute(dialog)', 'LogicalKeyboardKey.space',
    'SleepSettingsPanel(', 'isCurrent: permitted']) assert(modal.includes(required), required);
  assert(!/PlaybackController\(|Timer|Repository|WebView|navigator.pop\(/.test(modal));
});
