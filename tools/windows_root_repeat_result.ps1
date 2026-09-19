#Requires -Version 7.0
# Strict host-side projection for the independent Windows root Profile result.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][System.Collections.IDictionary]$Record,
    [Parameter(Mandatory)][string]$ExpectedCommit
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
function Test-Integer($Value) { return $Value -is [int] -or $Value -is [long] }
if ($ExpectedCommit -cnotmatch '^[0-9a-f]{40}$' -or
    -not (Test-Integer $Record.schemaVersion) -or $Record.schemaVersion -ne 1 -or
    $Record.sourceCommit -isnot [string] -or $Record.sourceCommit -cne $ExpectedCommit -or
    $Record.nativeCommit -isnot [string] -or $Record.nativeCommit -cne $ExpectedCommit -or
    $Record.platform -isnot [string] -or $Record.platform -cne 'windows' -or
    $Record.purpose -isnot [string] -or $Record.purpose -cne 'isolated-windows-root-repeat-test' -or
    $Record.passed -isnot [bool] -or -not $Record.passed -or
    -not (Test-Integer $Record.testCount) -or $Record.testCount -ne 1 -or
    $Record.diagnosticId -isnot [string] -or $Record.diagnosticId -cne 'windows-root-repeat.passed') {
    throw 'Invalid Windows root result identity or outcome'
}
$metrics = $Record.metrics
if ($metrics -isnot [System.Collections.IDictionary] -or
    $metrics.sourceCommit -isnot [string] -or $metrics.sourceCommit -cne $ExpectedCommit -or
    $metrics.platform -isnot [string] -or $metrics.platform -cne 'windows') {
    throw 'Missing or mismatched Windows root metrics'
}
$orders = [ordered]@{
    nativeEntries = @('q0', 'q1', 'q0'); nativeIndices = @(0, 1, 2); nativeCycles = @(0, 0, 1)
    rootEntries = @('q0', 'q1', 'q0'); persistedEntries = @('q0', 'q1', 'q0')
}
foreach ($key in $orders.Keys) {
    $values = $metrics[$key]
    if ($values -isnot [array] -or $values.Count -ne 3) { throw 'Invalid Windows root observation count' }
    for ($index = 0; $index -lt 3; $index++) {
        $expected = $orders[$key][$index]
        if ($expected -is [int]) {
            if (-not (Test-Integer $values[$index]) -or $values[$index] -ne $expected) { throw 'Invalid Windows root index' }
        } elseif ($values[$index] -isnot [string] -or $values[$index] -cne $expected) { throw 'Invalid Windows root entry' }
    }
}
foreach ($key in @('nativeProgressMs', 'rootProgressMs')) {
    $values = $metrics[$key]
    if ($values -isnot [array] -or $values.Count -ne 3) { throw 'Invalid Windows root clock count' }
    foreach ($value in $values) {
        if (-not (Test-Integer $value) -or $value -lt 100 -or $value -gt 10000) { throw 'Invalid Windows root clock' }
    }
}
$facts = @('sameNativeBatch', 'metadataAligned', 'historyReplaced', 'restoredWithoutPlayback', 'disposed')
foreach ($key in $facts) {
    if ($metrics[$key] -isnot [bool] -or -not $metrics[$key]) { throw 'Incomplete Windows root lifecycle' }
}
foreach ($key in @('noRestartObservedMs', 'restoreObservedMs')) {
    if (-not (Test-Integer $metrics[$key]) -or $metrics[$key] -lt 1000 -or $metrics[$key] -gt 10000) { throw 'Invalid Windows root quiet interval' }
}
foreach ($key in @('historyCount', 'completedIndex', 'completedCycle')) {
    $expected = if ($key -ceq 'completedCycle') { 1 } else { 2 }
    if (-not (Test-Integer $metrics[$key]) -or $metrics[$key] -ne $expected) { throw 'Invalid Windows root completion' }
}
if ($metrics.completedEntry -isnot [string] -or $metrics.completedEntry -cne 'q0' -or
    $metrics.restoredEntry -isnot [string] -or $metrics.restoredEntry -cne 'q0' -or
    $metrics.acousticGapMeasured -isnot [bool] -or $metrics.acousticGapMeasured) { throw 'Invalid Windows root restore or acoustic claim' }
$safe = [ordered]@{ sourceCommit = $ExpectedCommit; platform = 'windows' }
foreach ($key in $orders.Keys) { $safe[$key] = @($orders[$key]) }
foreach ($key in $facts) { $safe[$key] = $true }
foreach ($key in @('nativeProgressMs', 'rootProgressMs')) { $safe[$key] = @($metrics[$key]) }
foreach ($key in @('historyCount', 'completedEntry', 'completedIndex', 'completedCycle',
    'noRestartObservedMs', 'restoreObservedMs', 'restoredEntry', 'acousticGapMeasured')) { $safe[$key] = $metrics[$key] }
$safe
