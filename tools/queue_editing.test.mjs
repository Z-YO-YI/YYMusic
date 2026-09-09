import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('interactive queue edits use immutable complete identity and the existing root serial worker', () => {
  const model = read('lib/domain/models/queue_edit.dart');
  assert.match(model, /final QueueSnapshot expected/);
  assert.match(model, /beforeEntryId/);
  assert.match(model, /track: entries\[i\]\.track/);
  assert(!/package:flutter|dart:io|MethodChannel|Repository/.test(model));
  const core = read('lib/playback/queue_editing.dart');
  assert.match(core, /await _schedule/);
  assert.match(core, /identical\(_state.queue, edit.expected\)/);
  assert.match(core, /_commitQueue\(next, canCommit: allowed\)/);
  assert.match(core, /diagnosticId: 'queue.edit-failed'/);
  assert(!/_publishFailure|_guarded\(|Timer|_engine\.load|_engine\.play/.test(core));
  const facade = read('lib/playback/queue_controller.dart');
  assert.match(facade, /_playback.editQueue/);
  assert.match(facade, /canEdit: \(\) => !_disposed/);
  assert(!/saveQueue|QueueSnapshot _|List<QueueEntry> _/.test(facade));
});

test('queue feedback is root-retained, identity-bound and drained before engine or data disposal', () => {
  const facade = read('lib/playback/queue_controller.dart');
  assert.match(facade, /identical\(_editFailure, expected\)/);
  assert.match(facade, /identical\(state, expected.edit.expected\)/);
  assert.match(facade, /_editClose = _editWork/);
  const feedback = read('lib/playback/queue_edit_feedback.dart');
  assert.match(feedback, /_editWork = done.future.then<void>/);
  assert.match(feedback, /retrying != null && identical\(_editFailure, retrying\)/);
  assert.match(feedback, /_editBusy = false;[\s\S]*?done.complete\(result\)/);
  assert(!/Repository|saveQueue|_engine|Timer/.test(feedback));
  const graph = read('lib/app/dependency_graph.dart');
  assert.match(graph, /queue.close,[\s\S]*?playback.close,[\s\S]*?_audioEngine.dispose,[\s\S]*?services.dispose/);
  const model = read('lib/playback/queue_edit_result.dart');
  assert.match(model, /diagnosticId: 'queue.edit-failed'/);
  assert(!/Object\?? (error|exception)|error.toString|StackTrace/.test(model));
});
