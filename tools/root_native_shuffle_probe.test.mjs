import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';
import { root } from './design_audit.mjs';

const read = path => readFileSync(join(root, path), 'utf8');

test('shuffle probe uses real root and SQLite, seeded selection and natural completion', () => {
  const probe = read('integration_test/root_native_shuffle_poc_test.dart');
  for (const text of ['Random(_seed)', 'const _seed = 42', 'random.nextInt(upperBound)',
    'PlaybackController(', 'JustAudioEngine.create(', 'NativeDatabase.createInBackground(databaseFile)',
    'data.library.upsertTracks(', "root.playNativeSequence('q0')", 'root.setShuffleEnabled(true)',
    'root.setShuffleEnabled(false)', 'root.setRepeatMode(RepeatMode.all)',
    'root.setContinueAfterTrack(false)', 'data.collection.loadQueue()',
    'boundaryCompleted', 'beforeModePosition', 'randomCalls == callsAtChange',
    'await root.close()', 'await engine.dispose()', 'await data.dispose()',
    "'acousticGapMeasured': false"]) assert.ok(probe.includes(text), text);
  assert.doesNotMatch(probe, /FakeAudio|Mock|NativeDatabase\.memory|Future\.delayed|\.emit\(|\.seek\(|\.skipNext\(|\.loadSequence\(/);
  assert.match(probe, /expect\(nativeIndices, \[0, 1, 2, 3\]\)/);
  assert.match(probe, /expect\(nativeCycles, \[0, 0, 0, 1\]\)/);
});

test('shuffle result remains separate from repeat and Windows reports', () => {
  const probe = read('integration_test/root_native_shuffle_poc_test.dart');
  assert.match(probe, /binding\.allTestsPassed\.future/);
  assert.match(probe, /testCount: binding\.results\.length/);
  assert.match(probe, /debugPrintSynchronously/);
  assert.match(read('tools/verify_root_native_shuffle.dart'), /parseRootNativeShuffleLog/);
  assert.match(read('tools/verify_root_native_shuffle.dart'), /exitCode = 1/);
  for (const path of ['lib/main.dart', 'integration_test/root_native_repeat_poc_test.dart',
    'integration_test/windows_audio_probe.dart', 'integration_test/windows_sequence_probe.dart',
    'integration_test/just_audio_native_sequence_poc_test.dart']) {
    assert.doesNotMatch(read(path), /root_native_shuffle|ROOT_SHUFFLE/);
  }
});

test('shuffle workflow is opt-in Android-only and rejects mixed probe modes', () => {
  const workflow = read('.github/workflows/foundation.yml');
  assert.match(workflow, /include_root_shuffle_poc:[\s\S]*?default: false[\s\S]*?type: boolean/);
  assert.match(workflow, /if: inputs\.include_root_shuffle_poc && \(github\.event_name != 'workflow_dispatch' \|\| !inputs\.run_just_audio_poc \|\| inputs\.just_audio_poc_platform != 'android' \|\| inputs\.build_windows_audio_probe \|\| inputs\.include_https_audio_poc \|\| inputs\.include_sequence_audio_poc \|\| inputs\.include_root_repeat_poc\)/);
  const command = workflow.split('\n').find(line => line.includes("if [ '${{ inputs.include_root_shuffle_poc }}'"));
  assert.ok(command);
  assert.match(command, /flutter test --no-pub integration_test\/root_native_shuffle_poc_test\.dart/);
  assert.match(command, /--dart-define=YYMUSIC_ROOT_SHUFFLE_SOURCE_COMMIT=\$\{GITHUB_SHA\}/);
  assert.match(command, /2>&1 && dart run tools\/verify_root_native_shuffle\.dart/);
  assert.match(command, /yy_shuffle_status=\$\?; cat .*; exit "\$yy_shuffle_status"; fi/);
  assert.match(workflow, /dart format --output=none --set-exit-if-changed tools\/verify_root_native_shuffle\.dart/);
});
