import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('sleep storage serializes accepted work and borrows the shared database', () => {
  const source = read('lib/data/repositories/drift_sleep_timer_repository.dart');
  assert.match(source, /settingKey = 'playbackSleepTimer'/);
  assert.match(source, /row.settingKey.equals\(settingKey\)/);
  assert.match(source, /final result = _tail.then/);
  assert.match(source, /_tail = result.then<void>/);
  assert.match(source, /_closeFuture \?\?= _tail/);
  assert.match(source, /DomainFailureCode.schemaMismatch/);
  assert(!/\.close\(|PlaybackController|AudioEngine|\.play\(/.test(source));
});
