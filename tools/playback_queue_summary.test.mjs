import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('queue summary is synchronous read-only and presenter caches by root identity', () => {
  const summary = read('lib/app/playback_queue_summary.dart');
  assert(!/Timer|Repository|Controller|Future|Stream|WebView/.test(summary));
  assert.match(summary, /entry.id == currentId/);
  const presenter = read('lib/app/playback_presenter.dart');
  assert.match(presenter, /identical\(queue, _summaryQueue\)/);
  assert.match(presenter, /PlaybackQueueSummary.fromQueue\(queue\)/);
});
