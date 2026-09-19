import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { join } from 'node:path';
import test from 'node:test';
import { root } from './design_audit.mjs';

const commit = '1'.repeat(40);
const valid = {
  schemaVersion: 1, sourceCommit: commit, nativeCommit: commit,
  platform: 'windows', purpose: 'isolated-native-sequence-test',
  passed: true, testCount: 1, diagnosticId: 'sequence-poc.passed',
  sequenceMetrics: {
    observedIndices: [0, 1, 2], observedCycles: [0, 1, 2], progressMs: [100, 200, 300],
    appendAccepted: true, pruneAccepted: true, retainAccepted: true,
    completedAtIndex: 2, disposed: true, acousticGapMeasured: false,
    private: 'do-not-persist-private-value',
  },
};
function validate(record, expectedCommit = commit) {
  const json = Buffer.from(JSON.stringify(record)).toString('base64');
  const script = join(root, 'tools/native_sequence_result.ps1').replaceAll("'", "''");
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

test('external sequence validation projects only bounded verified data', () => {
  const result = validate(valid);
  assert.equal(result.status, 0, result.stderr);
  const metrics = JSON.parse(result.stdout.trim());
  assert.deepEqual(metrics.progressMs, [100, 200, 300]);
  assert.equal(metrics.acousticGapMeasured, false);
  assert.equal(metrics.private, undefined);
});

test('external sequence validation rejects wrong identity, counts, mode and outcome', () => {
  for (const change of [
    { schemaVersion: '1' }, { sourceCommit: '2'.repeat(40) }, { nativeCommit: '2'.repeat(40) },
    { platform: 'android' }, { purpose: 'isolated-local-wav-test' },
    { passed: false }, { passed: 'true' }, { testCount: 0 }, { testCount: 2 }, { testCount: '1' },
    { diagnosticId: 'sequence-poc.timeout' }, { sequenceMetrics: null },
  ]) assert.notEqual(validate({ ...valid, ...change }).status, 0, JSON.stringify(change));
  assert.notEqual(validate(valid, 'bad-commit').status, 0);
});

test('external sequence validation rejects incomplete or unbounded native evidence', () => {
  for (const change of [
    { observedIndices: [0, 2, 1] }, { observedCycles: [0, 1, 2, 3] },
    { progressMs: [0, 200, 300] }, { progressMs: [100, 10001, 300] },
    { progressMs: [100, '200', 300] }, { observedIndices: '0,1,2' },
    { appendAccepted: false }, { pruneAccepted: 'true' }, { retainAccepted: false },
    { disposed: false }, { completedAtIndex: '2' }, { acousticGapMeasured: true },
  ]) assert.notEqual(validate({ ...valid, sequenceMetrics: { ...valid.sequenceMetrics, ...change } }).status, 0);
  for (const key of Object.keys(valid.sequenceMetrics).filter(key => key !== 'private')) {
    const metrics = { ...valid.sequenceMetrics };
    delete metrics[key];
    assert.notEqual(validate({ ...valid, sequenceMetrics: metrics }).status, 0, key);
  }
});
