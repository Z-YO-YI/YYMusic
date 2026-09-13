import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('root restore uses one-shot permission and original deadline without autoplay', () => {
  const source = read('lib/playback/sleep_restore_actions.dart');
  assert.match(source, /captured == _sleepGeneration/);
  assert.match(source, /used = true/);
  assert.match(source, /snapshot.remainingAt\(_clock\(\)\)/);
  assert.match(source, /snapshot.deadline/);
  assert.match(source, /_armSleepWake\(restoredGeneration, remaining\)/);
  assert(!/\.play\(|_setSleepTimer\(|\.save\(|\.read\(/.test(source));
  const deadline = read('lib/playback/sleep_deadline_actions.dart');
  assert.match(deadline, /final wake = _sleepScheduler/);
  assert.match(deadline, /wake.cancel\(\)/);
});
