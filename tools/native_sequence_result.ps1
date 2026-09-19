#Requires -Version 7.0
# Pure validation/projection. Never emits the untrusted record or plugin errors.
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
    $Record.sourceCommit -cne $ExpectedCommit -or $Record.nativeCommit -cne $ExpectedCommit -or
    $Record.platform -cne 'windows' -or $Record.purpose -cne 'isolated-native-sequence-test' -or
    $Record.passed -isnot [bool] -or -not $Record.passed -or
    -not (Test-Integer $Record.testCount) -or $Record.testCount -ne 1 -or
    $Record.diagnosticId -cne 'sequence-poc.passed') { throw 'Invalid native sequence result identity or outcome' }
$metrics = $Record.sequenceMetrics
if ($metrics -isnot [System.Collections.IDictionary]) { throw 'Missing native sequence metrics' }
foreach ($key in @('observedIndices', 'observedCycles', 'progressMs')) {
    $values = $metrics[$key]
    if ($values -isnot [array] -or $values.Count -ne 3) { throw 'Invalid native sequence observation count' }
    for ($index = 0; $index -lt 3; $index++) {
        if (-not (Test-Integer $values[$index])) { throw 'Invalid native sequence observation type' }
        if ($key -ceq 'progressMs') {
            if ($values[$index] -lt 100 -or $values[$index] -gt 10000) { throw 'Invalid native sequence progress' }
        } elseif ($values[$index] -ne $index) { throw 'Invalid native sequence observation order' }
    }
}
foreach ($key in @('appendAccepted', 'pruneAccepted', 'retainAccepted', 'disposed')) {
    if ($metrics[$key] -isnot [bool] -or -not $metrics[$key]) { throw 'Incomplete native sequence lifecycle' }
}
if (-not (Test-Integer $metrics.completedAtIndex) -or $metrics.completedAtIndex -ne 2 -or
    $metrics.acousticGapMeasured -isnot [bool] -or $metrics.acousticGapMeasured) {
    throw 'Invalid native sequence completion or acoustic claim'
}
[ordered]@{
    observedIndices = @(0, 1, 2); observedCycles = @(0, 1, 2); progressMs = @($metrics.progressMs)
    appendAccepted = $true; pruneAccepted = $true; retainAccepted = $true
    completedAtIndex = 2; disposed = $true; acousticGapMeasured = $false
}
