import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('Inspector queue summary uses root projection and protected existing navigation', () => {
  const shell = read('lib/features/player/common/shell_player.dart');
  assert.match(shell, /final summary = presenter.queueSummary/);
  assert.match(shell, /onOpenQueue: _queueAction\(favoriteGeneration\)/);
  assert.match(shell, /currentQueueOrdinal: summary.currentOrdinal/);
  const inspector = read('lib/design_system/yy_now_playing_inspector.dart');
  assert.match(inspector, /inspector-open-queue/);
  assert(!inspector.includes('队列详情正在开发'));
  assert(!/Repository|Timer|PlaybackController|WebView/.test(inspector));
});
