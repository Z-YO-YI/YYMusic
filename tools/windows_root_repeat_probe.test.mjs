import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';
import { root } from './design_audit.mjs';

const read = path => readFileSync(join(root, path), 'utf8');
const commit = '1'.repeat(40);
const metrics = {
  sourceCommit: commit, platform: 'windows',
  nativeEntries: ['q0', 'q1', 'q0'], nativeIndices: [0, 1, 2], nativeCycles: [0, 0, 1],
  rootEntries: ['q0', 'q1', 'q0'], persistedEntries: ['q0', 'q1', 'q0'],
  nativeProgressMs: [100, 200, 300], rootProgressMs: [100, 200, 300],
  sameNativeBatch: true, metadataAligned: true, historyReplaced: true,
  restoredWithoutPlayback: true, disposed: true, historyCount: 2,
  completedEntry: 'q0', completedIndex: 2, completedCycle: 1,
  noRestartObservedMs: 1200, restoreObservedMs: 1200, restoredEntry: 'q0',
  acousticGapMeasured: false, private: 'do-not-expose-this-value',
};
const valid = {
  schemaVersion: 1, sourceCommit: commit, nativeCommit: commit,
  platform: 'windows', purpose: 'isolated-windows-root-repeat-test',
  passed: true, testCount: 1, diagnosticId: 'windows-root-repeat.passed', metrics,
};
function validate(record, expectedCommit = commit) {
  const json = Buffer.from(JSON.stringify(record)).toString('base64');
  const script = join(root, 'tools/windows_root_repeat_result.ps1').replaceAll("'", "''");
  const command = `$ErrorActionPreference = 'Stop'
    $record = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('${json}')) | ConvertFrom-Json -AsHashtable
    & '${script}' -Record $record -ExpectedCommit '${expectedCommit}' | ConvertTo-Json -Depth 5 -Compress`;
  const result = spawnSync('pwsh', ['-NoProfile', '-NonInteractive', '-EncodedCommand', Buffer.from(command, 'utf16le').toString('base64')], {
    encoding: 'utf8', timeout: 30000, windowsHide: true,
  });
  assert.ifError(result.error);
  assert.equal(result.signal, null);
  return result;
}

test('Windows root host gate emits only complete bounded facts', () => {
  const result = validate(valid);
  assert.equal(result.status, 0, result.stderr);
  const projected = JSON.parse(result.stdout.trim());
  assert.deepEqual(projected.nativeCycles, [0, 0, 1]);
  assert.equal(projected.restoredWithoutPlayback, true);
  assert.equal(projected.private, undefined);
  assert.equal(projected.acousticGapMeasured, false);
});

test('Windows root host gate rejects foreign failed or malformed reports', () => {
  for (const change of [
    { schemaVersion: '1' }, { sourceCommit: '2'.repeat(40) }, { nativeCommit: '2'.repeat(40) },
    { platform: 'android' }, { purpose: 'isolated-root-native-repeat-test' },
    { passed: false }, { passed: 'true' }, { testCount: 0 }, { testCount: 2 }, { testCount: '1' },
    { diagnosticId: 'root-repeat.passed' }, { metrics: null },
    ...['sourceCommit', 'nativeCommit', 'platform', 'purpose', 'diagnosticId']
      .flatMap(key => [{ [key]: [valid[key]] }, { [key]: [] }, { [key]: null }]),
  ]) assert.notEqual(validate({ ...valid, ...change }).status, 0);
  assert.notEqual(validate(valid, 'short-sha').status, 0);
});

test('Windows root host gate rejects missing clocks history and cleanup', () => {
  for (const change of [
    { sourceCommit: '2'.repeat(40) }, { platform: 'android' },
    { nativeIndices: [0, 1, '2'] }, { nativeCycles: [0, 1, 2] },
    { nativeEntries: ['q0', 'q1'] }, { persistedEntries: ['q0', 'q1', 'q1'] },
    { rootEntries: 'q0,q1,q0' }, { nativeProgressMs: [99, 200, 300] },
    { rootProgressMs: [100, 200, 10001] }, { historyReplaced: false },
    { sameNativeBatch: 'true' }, { metadataAligned: false }, { historyCount: '2' },
    { completedEntry: 'q1' }, { completedIndex: 1 }, { completedCycle: 2 },
    { noRestartObservedMs: 999 }, { restoreObservedMs: 10001 }, { restoredEntry: 'q1' },
    { restoredWithoutPlayback: false }, { disposed: false }, { acousticGapMeasured: true },
    ...['sourceCommit', 'platform', 'completedEntry', 'restoredEntry']
      .flatMap(key => [{ [key]: [metrics[key]] }, { [key]: [] }, { [key]: null }]),
  ]) assert.notEqual(validate({ ...valid, metrics: { ...metrics, ...change } }).status, 0);
  for (const key of Object.keys(metrics).filter(key => key !== 'private')) {
    const incomplete = { ...metrics };
    delete incomplete[key];
    assert.notEqual(validate({ ...valid, metrics: incomplete }).status, 0, key);
  }
});

test('Windows root entry waits for teardown and cannot enter ordinary or foreign modes', () => {
  const entry = read('integration_test/windows_root_repeat_probe.dart');
  for (const marker of ['!kProfileMode', '!Platform.isWindows', '!enabled',
    'sourceCommit != nativeCommit', 'resultFile.existsSync()',
    'registerRootNativeRepeatScenario(', 'platform: RootRepeatPlatform.windows',
    'binding.allTestsPassed.future.timeout(', 'testCount: binding.results.length',
    'root-native-repeat-poc-result.json', "exit(result['passed'] == true ? 0 : 1)"]) {
    assert(entry.includes(marker), marker);
  }
  for (const path of ['lib/main.dart', 'integration_test/windows_audio_probe.dart',
    'integration_test/windows_sequence_probe.dart']) assert.doesNotMatch(read(path), /windows_root_repeat|WINDOWS_ROOT_REPEAT/);
  const workflow = read('.github/workflows/foundation.yml');
  assert.match(workflow, /include_windows_root_repeat_poc:[\s\S]*?default: false[\s\S]*?type: boolean/);
  const guard = workflow.split('\n').find(l => l.includes('if: inputs.include_windows_root_repeat_poc'));
  for (const clause of ["github.event_name != 'workflow_dispatch'", '!inputs.build_windows_audio_probe',
    'inputs.run_just_audio_poc', 'inputs.include_https_audio_poc', 'inputs.include_sequence_audio_poc',
    'inputs.include_root_repeat_poc', 'inputs.include_root_shuffle_poc']) assert(guard.includes(clause));
  assert.match(workflow, /--dart-define=YYMUSIC_WINDOWS_ROOT_REPEAT_PROBE=\$\{\{ inputs.include_windows_root_repeat_poc \}\}/);
  assert.match(workflow, /--dart-define=YYMUSIC_ROOT_REPEAT_SOURCE_COMMIT=\$env:GITHUB_SHA/);
  assert.match(workflow, /integration_test\/windows_root_repeat_probe\.dart/);
  assert.match(workflow, /-IncludeRootRepeat:\$includeRootRepeat/);
  assert.match(workflow, /inputs.include_windows_root_repeat_poc && 'root-repeat'/);
});

test('Windows root packaging and runner keep separate metadata and final result', () => {
  const metadata = read('tools/windows_audio_profile_metadata.ps1');
  const runner = read('tools/windows_audio_probe.ps1');
  assert.match(metadata, /IncludeRootRepeat -and \(\$IncludeHttps -or \$IncludeSequence\)/);
  assert.match(metadata, /native-root-repeat-build\.json/);
  assert.match(metadata, /isolated-windows-root-repeat-test/);
  assert.match(runner, /Get-RootRepeatMode \$manifest/);
  assert.match(runner, /Get-RootRepeatMode \$metadata/);
  assert.match(runner, /root-native-repeat-poc-result\.json/);
  assert.match(runner, /windows_root_repeat_result\.ps1/);
  assert.match(runner, /Windows root process or identity failed/);
  assert.match(runner, /Windows root probe requires an isolated Profile bundle/);
  assert.doesNotMatch(runner, /Set-Service|Set-ItemProperty|Remove-Item|Invoke-RestMethod/);
});
