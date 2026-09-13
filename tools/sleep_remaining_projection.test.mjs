import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('remaining time reads original root clock without mutating business intent', () => {
  const root = read('lib/playback/playback_controller.dart');
  const getter = root.split('Duration? get sleepRemaining {')[1].split('/// Null cancels.')[0];
  assert.match(getter, /deadline.difference\(_clock\(\).toUtc\(\)\)/);
  assert(!/notifyListeners|_publish|_cancel|_schedule|_engine\./.test(getter));
  const presenter = read('lib/app/playback_presenter.dart');
  assert.match(presenter, /final remaining = _playback.sleepRemaining/);
  assert.match(presenter, /Duration.microsecondsPerSecond - 1/);
});
