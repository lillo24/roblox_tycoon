param(
    [ValidateRange(5,900)][int]$Seconds = 360,
    [ValidateRange(5,30)][int]$Interval = 5,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-z0-9-]+$')][string]$Name
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root "build/perf-host-$Name.jsonl"
foreach ($path in @((Join-Path $root 'build'), $output)) {
    if (Test-Path -LiteralPath $path) {
        $item = Get-Item -LiteralPath $path -Force
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or $item.LinkType) { throw "Linked host-observation output refused: $path" }
    }
}
[void][IO.Directory]::CreateDirectory((Split-Path $output -Parent))
$rows = [Collections.Generic.List[string]]::new()
$timer = [Diagnostics.Stopwatch]::StartNew()
while ($timer.Elapsed.TotalSeconds -lt $Seconds) {
    $sampleStart = $timer.Elapsed.TotalSeconds
    # Raw English WMI class/property names work on localized Windows. Preserve
    # counters and their own timestamps for later rates; never call them frame CPU.
    $cpu = @(Get-CimInstance Win32_PerfRawData_PerfOS_Processor | ForEach-Object {
        @{ core = $_.Name; idle100ns = $_.PercentProcessorTime; time100ns = $_.Timestamp_Sys100NS }
    })
    $memory = Get-CimInstance Win32_PerfRawData_PerfOS_Memory
    $gpu = @(Get-CimInstance Win32_PerfRawData_GPUPerformanceCounters_GPUEngine | Where-Object Name -Like '*engtype_3D*' | ForEach-Object {
        @{ engine = $_.Name; busy100ns = $_.UtilizationPercentage; time100ns = $_.Timestamp_Sys100NS }
    })
    $processes = @(Get-Process -Name RobloxStudioBeta -ErrorAction SilentlyContinue | ForEach-Object {
        @{ pid = $_.Id; cpuSeconds = $_.CPU; workingSetBytes = $_.WorkingSet64; privateBytes = $_.PrivateMemorySize64 }
    })
    $rows.Add((@{
        utc = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() / 1000.0
        cpuRaw = $cpu; gpu3dRaw = $gpu; processes = $processes
        memoryRaw = @{ availableMB = $memory.AvailableMBytes; pageReads = $memory.PageReadsPersec; pagesInput = $memory.PagesInputPersec
            time = $memory.Timestamp_PerfTime; frequency = $memory.Frequency_PerfTime }
        collectionMs = ($timer.Elapsed.TotalSeconds - $sampleStart) * 1000
        collectorCpuSeconds = (Get-Process -Id $PID).CPU
    } | ConvertTo-Json -Depth 8 -Compress))
    $remaining = $Interval - ($timer.Elapsed.TotalSeconds - $sampleStart)
    if ($remaining -gt 0) { Start-Sleep -Milliseconds ([int]($remaining * 1000)) }
}
# A bounded buffer, no periodic console/file writes during the gameplay window.
[IO.File]::WriteAllLines($output, $rows, [Text.UTF8Encoding]::new($false))
Write-Output "Host observations: $($rows.Count) samples in $output"
