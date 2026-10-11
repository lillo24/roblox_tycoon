param(
    [Parameter(Mandatory=$true)][string[]]$LogPaths,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-z0-9-]+$')][string]$Name,
    [string]$OutputDirectory = ''
)
$ErrorActionPreference = 'Stop'
if (-not $OutputDirectory) { $OutputDirectory = Join-Path (Split-Path $PSScriptRoot -Parent) 'docs/perf-01' }
[void][IO.Directory]::CreateDirectory($OutputDirectory)
$rows = @(
    foreach ($path in $LogPaths) {
        foreach ($line in (Get-Content -LiteralPath $path)) {
            if ($line -match '\[FLog::CreatorOutput\] PERF01 (\{.*)$') {
                try { $Matches[1] | ConvertFrom-Json } catch { throw "Incomplete PERF01 JSON in $path. Use the bounded 64-sample probe; truncated output cannot establish percentiles." }
            }
        }
    }
) | Sort-Object time
if (-not $rows) { throw "No PERF01 JSON output found in: $($LogPaths -join ', ')" }
$start = @($rows | Where-Object { $_.kind -eq 'phase' -and $_.phase -in @('Warmup','Churn') })[0]
if (-not $start) { throw 'No sampling phase observed; idle logs are not a completed measurement.' }
$rows = @($rows | Where-Object { $_.time -ge $start.time - 5 })
# Save probe JSON only, never arbitrary Creator output or account-identifying log names.
$aliases = @{}
$index = 0
foreach ($side in @($rows.side | Where-Object { $_ -like 'client:*' } | Sort-Object -Unique)) {
    $index += 1
    $aliases[$side] = "client:owner$index"
}
$json = foreach ($row in $rows) {
    if ($aliases.ContainsKey([string]$row.side)) { $row.side = $aliases[$row.side] }
    $row | ConvertTo-Json -Depth 12 -Compress
}
$utf8 = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllLines((Join-Path $OutputDirectory "$Name.jsonl"), [string[]]$json, $utf8)
function Distribution($Values) {
    $sorted = @($Values | Sort-Object)
    if (-not $sorted.Count) { throw 'Cannot summarize an empty measurement.' }
    $spikes = @($sorted | Where-Object { $_ -gt 50 }).Count
    [ordered]@{
        count = $sorted.Count
        p50 = $sorted[[Math]::Ceiling($sorted.Count * 0.5) - 1]
        p95 = $sorted[[Math]::Ceiling($sorted.Count * 0.95) - 1]
        p99 = $sorted[[Math]::Ceiling($sorted.Count * 0.99) - 1]
        max = $sorted[-1]
        above50Percent = [Math]::Round(100 * $spikes / $sorted.Count, 4)
    }
}
$series = foreach ($group in ($rows | Where-Object kind -eq 'series' | Group-Object side,metric)) {
    [ordered]@{ side = $group.Group[0].side; metric = $group.Group[0].metric; distribution = Distribution @($group.Group.values | ForEach-Object { $_ }) }
}
$stats = foreach ($group in ($rows | Where-Object kind -eq 'stats' | Group-Object side,phase,focused)) {
    $metrics = [ordered]@{}
    foreach ($key in @('luaKB','totalMB','luaMB','instances','guiInstances','ghosts','worldParts','animatedParts','addedParts','removedParts','receiveKbps','sendKbps','renderCPUms','renderGPUms','heartbeatWorkMs','physicsWorkMs')) {
        $values = @($group.Group | ForEach-Object { if ($null -ne $_.$key) { $_.$key } })
        if ($values.Count) {
            $metrics[$key] = [ordered]@{ first = $values[0]; last = $values[-1]; min = ($values | Measure-Object -Minimum).Minimum; max = ($values | Measure-Object -Maximum).Maximum; mean = ($values | Measure-Object -Average).Average }
        }
    }
    [ordered]@{ side = $group.Group[0].side; phase = $group.Group[0].phase; focused = $group.Group[0].focused; observations = $group.Count; metrics = $metrics }
}
$summary = [ordered]@{ name = $Name; start = $rows[0].time; finish = $rows[-1].time; series = @($series); stats = @($stats); completed = @($rows | Where-Object kind -eq 'complete'); checkpoints = @($rows | Where-Object kind -eq 'checkpoint') }
[IO.File]::WriteAllText((Join-Path $OutputDirectory "$Name-summary.json"), ($summary | ConvertTo-Json -Depth 15), $utf8)
Write-Output "$Name`: $($rows.Count) probe records; $($series.Count) series; $(@($summary.completed).Count) completed windows."
