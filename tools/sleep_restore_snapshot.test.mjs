import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('sleep restore snapshot remains domain-only and does not wire premature restore', () => {
  const model = read('lib/domain/models/sleep_timer_snapshot.dart');
  assert(!/package:flutter|playback_controller|DateTime\.now\s*\(|\bTimer\(/.test(model));
  assert.match(model, /deadline.difference\(now.toUtc\(\)\)/);
  const codec = read('lib/data/sleep_timer_snapshot_codec.dart');
  assert.match(codec, /source.length > 512/);
  assert.match(codec, /value\['version'\] != 1/);
  assert(!/\.play\(|\.pause\(|\.save\(|\.clear\(/.test(codec));
  const contract = read('lib/domain/repositories/sleep_timer_repository.dart');
  assert.match(contract, /invocation order/);
  assert.match(contract, /Future<void> clear\(\)/);
});
