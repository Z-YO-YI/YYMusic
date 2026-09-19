import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';
import { root } from './design_audit.mjs';

const read = path => readFileSync(join(root, path), 'utf8');

test('root device probe uses production root and file SQLite with natural native events', () => {
  const probe = read('integration_test/support/root_native_repeat_scenario.dart');
  for (const evidence of [
    'JustAudioEngine.create(', 'PlaybackController(',
    'NativeDatabase.createInBackground(databaseFile)', 'data.library.upsertTracks(',
    'root.playNativeSequence(\'q0\')', 'root.setRepeatMode(RepeatMode.all)',
    'root.setContinueAfterTrack(false)', 'engine.states.listen(',
    'data.collection.loadQueue()', 'data.collection.watchHistory()',
    'heard.id != initialHistoryId', 'heard.startedAt.isAfter(initialHistoryTime!)',
    'final restoredData = await openData()', 'await restored.initialize()',
    'await root.close()', 'await engine.dispose()', 'await data.dispose()',
    "'acousticGapMeasured': false",
  ]) assert.ok(probe.includes(evidence), evidence);
  assert.doesNotMatch(probe, /FakeAudio|Mock|NativeDatabase\.memory|Future\.delayed|\.emit\(|\.seek\(|\.skipNext\(|\.loadSequence\(/);
  assert.match(probe, /expect\(nativeIndices, \[0, 1, 2\]\)/);
  assert.match(probe, /expect\(nativeCycles, \[0, 0, 1\]\)/);
  const android = read('integration_test/root_native_repeat_poc_test.dart');
  assert.match(android, /registerRootNativeRepeatScenario\(/);
  assert.match(android, /platform: RootRepeatPlatform\.android/);
  assert.match(probe, /expect\(Platform\.operatingSystem, platform\.name\)/);
});

test('root report waits for runner teardown and has a separate host gate', () => {
  const probe = read('integration_test/root_native_repeat_poc_test.dart');
  assert.match(probe, /binding\.allTestsPassed\.future\.timeout/);
  assert.match(probe, /testCount: binding\.results\.length/);
  assert.match(probe, /debugPrintSynchronously/);
  assert.match(probe, /YYMUSIC_ROOT_REPEAT_SOURCE_COMMIT/);
  assert.match(read('tools/verify_root_native_repeat.dart'), /parseRootNativeRepeatLog/);
  assert.match(read('tools/verify_root_native_repeat.dart'), /exitCode = 1/);
  for (const path of ['lib/main.dart', 'integration_test/windows_audio_probe.dart',
    'integration_test/windows_sequence_probe.dart', 'integration_test/just_audio_native_sequence_poc_test.dart']) {
    assert.doesNotMatch(read(path), /root_native_repeat|ROOT_REPEAT/);
  }
});

test('root workflow is explicit Android-only and preserves failure before log validation', () => {
  const workflow = read('.github/workflows/foundation.yml');
  assert.match(workflow, /include_root_repeat_poc:[\s\S]*?default: false[\s\S]*?type: boolean/);
  assert.match(workflow, /dart format --output=none --set-exit-if-changed tools\/verify_root_native_repeat\.dart/);
  assert.match(workflow, /if: inputs\.include_root_repeat_poc && \(github\.event_name != 'workflow_dispatch' \|\| !inputs\.run_just_audio_poc \|\| inputs\.just_audio_poc_platform != 'android' \|\| inputs\.build_windows_audio_probe \|\| inputs\.include_https_audio_poc \|\| inputs\.include_sequence_audio_poc\)/);
  const command = workflow.split('\n').find(line => line.includes("if [ '${{ inputs.include_root_repeat_poc }}'"));
  assert.ok(command);
  assert.match(command, /flutter test --no-pub integration_test\/root_native_repeat_poc_test\.dart/);
  assert.match(command, /--dart-define=YYMUSIC_ROOT_REPEAT_SOURCE_COMMIT=\$\{GITHUB_SHA\}/);
  assert.match(command, /2>&1 && dart run tools\/verify_root_native_repeat\.dart/);
  assert.match(command, /yy_root_status=\$\?; cat .*; exit "\$yy_root_status"; fi/);
});
