import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('app scope owns sleep persistence and freezes it before root shutdown', () => {
  const graph = read('lib/app/dependency_graph.dart');
  assert.match(graph, /repository: dataServices\?\.sleepTimers \?\? sleepTimerRepository/);
  assert.match(graph, /await sleepPersistence.initialize\(\)/);
  assert(graph.indexOf('sleepPersistence.dispose();') < graph.indexOf('playback.dispose();'));
  const data = read('lib/app/database_app_data_services.dart');
  assert.match(data, /sleepTimers: DriftSleepTimerRepository\(database\)/);
  assert.match(data, /_sleepTimers.dispose\(\)/);
  const controller = read('lib/playback/sleep_persistence_controller.dart');
  assert.match(controller, /captureSleepRestore\(\)/);
  assert(!/\.play\(|Timer\(|\.setSleepTimer\(/.test(controller));
  const panel = read('lib/features/player/common/sleep_settings_panel.dart');
  assert.match(panel, /sleep-storage-retry/);
  assert.match(panel, /presenter.retrySleepPersistence\(storageFailure\)/);
});
