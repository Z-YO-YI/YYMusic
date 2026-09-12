import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('lyrics settings reuses root modal with explicit page owner and original more glyph', () => {
  const lyrics = read('lib/features/lyrics/common/lyrics_screen.dart');
  assert.match(lyrics, /lyrics-page-settings[\s\S]*?glyph: YYGlyph.more/);
  assert(lyrics.includes('onPressed: action(true, widget.onOpenSettings!)'));
  assert(lyrics.includes('oldWidget.onOpenSettings != widget.onOpenSettings'));
  const router = read('lib/app/app_router.dart');
  assert.match(router, /onOpenSettings: \(\) => _openSleepSettings\(\s+playbackPresenter,\s+platform,\s+owner: AppRoute.lyrics,/);
  const modal = read('lib/app/sleep_settings_route.dart');
  assert(modal.includes('required AppRoute owner'));
  assert(modal.includes('_activePath != owner.path'));
  assert(modal.includes('_activePath == ownerPath'));
  assert(!/PlaybackController\(|\bTimer\b|Repository|WebView/.test(modal));
});
