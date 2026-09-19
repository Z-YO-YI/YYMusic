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

test('sequence diagnostics are isolated opt-in modes and retain original source tests', () => {
  const workflow = read('.github/workflows/foundation.yml');
  assert.match(workflow, /include_sequence_audio_poc:[\s\S]*?default: false[\s\S]*?type: boolean/);
  assert.match(workflow, /if: inputs\.include_sequence_audio_poc && \(github\.event_name != 'workflow_dispatch' \|\| inputs\.include_https_audio_poc \|\| !\(\(inputs\.run_just_audio_poc && inputs\.just_audio_poc_platform == 'android' && !inputs\.build_windows_audio_probe\) \|\| \(inputs\.build_windows_audio_probe && !inputs\.run_just_audio_poc\)\)\)/);
  assert.match(workflow, /integration_test\/just_audio_android_sources_poc_test\.dart/);
  assert.match(workflow, /if \[ '\$\{\{ inputs\.include_sequence_audio_poc \}\}' = 'true' \]; then/);
  assert.match(workflow, /--dart-define=YYMUSIC_SEQUENCE_SOURCE_COMMIT=\$\{GITHUB_SHA\}/);
  assert.match(read('integration_test/support/windows_audio_probe_result.dart'), /testCount == \(includeHttps \? 2 : 1\)/);
});

test('Windows sequence entry waits for teardown and cannot replace the old or production entry', () => {
  const entry = read('integration_test/windows_sequence_probe.dart');
  assert.match(entry, /!kProfileMode/);
  assert.match(entry, /!Platform\.isWindows/);
  assert.match(entry, /YYMUSIC_WINDOWS_SEQUENCE_PROBE/);
  assert.match(entry, /sourceCommit != nativeCommit/);
  assert.match(entry, /sequence_poc\.main\(\)/);
  assert.match(entry, /allTestsPassed\.future\.timeout/);
  assert.match(entry, /testCount: binding\.results\.length/);
  assert.match(entry, /existing-result-refused/);
  assert.match(entry, /exit\(result\['passed'\] == true \? 0 : 1\)/);
  assert.doesNotMatch(read('lib/main.dart'), /windows_sequence_probe/);
  assert.doesNotMatch(read('integration_test/windows_audio_probe.dart'), /sequence/);
  const workflow = read('.github/workflows/foundation.yml');
  assert.match(workflow, /\$probeTarget = if \(\$includeSequence\) \{ 'integration_test\/windows_sequence_probe\.dart' \} else \{ 'integration_test\/windows_audio_probe\.dart' \}/);
  assert.match(workflow, /-IncludeSequence:\$includeSequence/);
  assert.match(workflow, /YYMusic-windows-\$\{\{ inputs\.include_sequence_audio_poc && 'sequence' \|\| 'audio' \}\}-probe/);
  assert.match(read('integration_test/just_audio_native_sequence_poc_test.dart'), /'progressMs': \[\s*first\.position\.inMilliseconds,\s*second\.position\.inMilliseconds,\s*appended\.position\.inMilliseconds/);
});
