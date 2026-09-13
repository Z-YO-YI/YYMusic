import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('sleep countdown binds host permission and never owns business pause', () => {
  const panel = read('lib/features/player/common/sleep_settings_panel.dart');
  assert.match(panel, /SleepRemainingText\(/);
  assert.match(panel, /active: _surfaceActive && !_closing/);
  assert.match(panel, /isCurrent: \(\) => _allowed\(generation\)/);
  const text = read('lib/features/player/common/sleep_remaining_text.dart');
  assert.match(text, /widget.presenter.sleepRemainingSeconds/);
  assert.match(text, /liveRegion: false/);
  assert(!/\.pause\(|\.play\(|setSleepTimer|setSleepAtCurrentEntryEnd/.test(text));
  assert.match(text, /_refresh\?\.cancel\(\)/);
});
