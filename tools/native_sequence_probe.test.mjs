import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';
import { root } from './design_audit.mjs';

const read = path => readFileSync(join(root, path), 'utf8');

test('sequence device probe uses real engine events and remains outside production', () => {
  const probe = read('integration_test/just_audio_native_sequence_poc_test.dart');
  for (const call of ['loadSequence', 'appendSequence', 'pruneSequenceBefore', 'retainSequenceThrough', 'dispose']) {
    assert.ok(probe.includes(`.${call}(`), call);
  }
  assert.match(probe, /JustAudioEngine\.create/);
  assert.match(probe, /engine\.states\.listen/);
  assert.match(probe, /\.firstWhere\(accepted\)/);
  assert.match(probe, /YYMUSIC_SEQUENCE_SOURCE_COMMIT/);
  assert.match(probe, /expect\(indices, \{0, 1, 2\}\)/);
  assert.match(probe, /'acousticGapMeasured': false/);
  assert.doesNotMatch(probe, /FakeAudio|Mock|Future\.delayed|\.emit\(/);
  assert.doesNotMatch(read('lib/main.dart'), /native_sequence_poc/);
  assert.doesNotMatch(read('integration_test/windows_audio_probe.dart'), /native_sequence_poc/);
});

test('sequence diagnostics are opt-in Android-only and retain original source tests', () => {
  const workflow = read('.github/workflows/foundation.yml');
  assert.match(workflow, /include_sequence_audio_poc:[\s\S]*?default: false[\s\S]*?type: boolean/);
  assert.match(workflow, /if: inputs\.include_sequence_audio_poc && \(github\.event_name != 'workflow_dispatch' \|\| !inputs\.run_just_audio_poc \|\| inputs\.just_audio_poc_platform != 'android' \|\| inputs\.include_https_audio_poc \|\| inputs\.build_windows_audio_probe\)/);
  assert.match(workflow, /integration_test\/just_audio_android_sources_poc_test\.dart/);
  assert.match(workflow, /if \[ '\$\{\{ inputs\.include_sequence_audio_poc \}\}' = 'true' \]; then/);
  assert.match(workflow, /--dart-define=YYMUSIC_SEQUENCE_SOURCE_COMMIT=\$\{GITHUB_SHA\}/);
  assert.match(read('integration_test/support/windows_audio_probe_result.dart'), /testCount == \(includeHttps \? 2 : 1\)/);
});
