import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('continuation persistence is app-owned and drains before data disposal', () => {
  const graph = read('lib/app/dependency_graph.dart');
  assert.match(graph, /repository: dataServices\?\.playbackContinuation \?\? continuationRepository/);
  assert.match(graph, /await continuationPersistence.initialize\(\)/);
  assert(graph.indexOf('continuationPersistence.dispose();') < graph.indexOf('playback.dispose();'));
  assert(graph.indexOf('continuationPersistence.close,') < graph.indexOf('services.dispose'));
  const data = read('lib/app/database_app_data_services.dart');
  assert.match(data, /playbackContinuation: DriftPlaybackContinuationRepository\(database\)/);
  assert.match(data, /_playbackContinuation.dispose\(\)/);
  const bridge = read('lib/playback/continuation_persistence_controller.dart');
  assert.match(bridge, /captureContinuationRestore\(\)/);
  assert(!/\.play\(|\.seek\(|\.load\(|\.clear\(|repository!\.dispose\(/.test(bridge));
});
