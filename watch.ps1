# watch.ps1
# Watch template.html and fengshen-diagrams/*.mmd; auto-run build.ps1 on save.
# Portable: uses $PSScriptRoot. Press Ctrl+C to stop.
# Usage:  .\watch.ps1
#         powershell -ExecutionPolicy Bypass -File "<path>\watch.ps1"

$ErrorActionPreference = 'Stop'
$root         = $PSScriptRoot
$buildScript  = Join-Path $root 'build.ps1'
$diagDir      = Join-Path $root 'fengshen-diagrams'
$templatePath = Join-Path $root 'template.html'

if (-not (Test-Path $buildScript))  { throw "build.ps1 not found at $buildScript" }
if (-not (Test-Path $diagDir))      { throw "fengshen-diagrams/ not found at $diagDir" }
if (-not (Test-Path $templatePath)) { throw "template.html not found at $templatePath" }

$DEBOUNCE_MS = 400

# Synchronized state shared between FileSystemWatcher event handlers and main loop.
$sync = [hashtable]::Synchronized(@{
    pending    = $false
    lastChange = [DateTime]::Now
})

function Invoke-Build {
    try {
        & $buildScript
    } catch {
        Write-Host ("  [ERR] build failed: " + $_.Exception.Message) -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "  Mermaid Studio Watcher" -ForegroundColor Green
Write-Host ("    watching   {0}\*.mmd" -f $diagDir)  -ForegroundColor DarkGray
Write-Host ("    watching   {0}" -f $templatePath)   -ForegroundColor DarkGray
Write-Host  "    debounce   $DEBOUNCE_MS ms"          -ForegroundColor DarkGray
Write-Host  "    press Ctrl+C to stop"                -ForegroundColor DarkGray
Write-Host ""

Write-Host "  -> initial build" -ForegroundColor Cyan
Invoke-Build

# Watcher 1: fengshen-diagrams/*.mmd (create / change / delete / rename)
$w1 = New-Object System.IO.FileSystemWatcher
$w1.Path                  = $diagDir
$w1.Filter                = '*.mmd'
$w1.IncludeSubdirectories = $false
$w1.NotifyFilter          = [System.IO.NotifyFilters]'FileName, LastWrite, Size'

# Watcher 2: template.html (changes only)
$w2 = New-Object System.IO.FileSystemWatcher
$w2.Path                  = $root
$w2.Filter                = 'template.html'
$w2.IncludeSubdirectories = $false
$w2.NotifyFilter          = [System.IO.NotifyFilters]'LastWrite, Size'

# Event handler. Marks pending=true and records last change time for debounce.
$onChange = {
    $st   = $Event.MessageData
    $name = $Event.SourceEventArgs.Name
    $kind = $Event.SourceEventArgs.ChangeType
    $st.pending    = $true
    $st.lastChange = [DateTime]::Now
    Write-Host ("  [{0,-8}] {1}" -f $kind, $name) -ForegroundColor Yellow
}

$subs = @()
$subs += Register-ObjectEvent -InputObject $w1 -EventName Changed -Action $onChange -MessageData $sync
$subs += Register-ObjectEvent -InputObject $w1 -EventName Created -Action $onChange -MessageData $sync
$subs += Register-ObjectEvent -InputObject $w1 -EventName Deleted -Action $onChange -MessageData $sync
$subs += Register-ObjectEvent -InputObject $w1 -EventName Renamed -Action $onChange -MessageData $sync
$subs += Register-ObjectEvent -InputObject $w2 -EventName Changed -Action $onChange -MessageData $sync

$w1.EnableRaisingEvents = $true
$w2.EnableRaisingEvents = $true

try {
    while ($true) {
        if ($sync.pending) {
            $sinceMs = ([DateTime]::Now - $sync.lastChange).TotalMilliseconds
            if ($sinceMs -ge $DEBOUNCE_MS) {
                $sync.pending = $false
                Write-Host "  -> rebuilding" -ForegroundColor Cyan
                Invoke-Build
            }
        }
        Start-Sleep -Milliseconds 150
    }
} finally {
    $w1.EnableRaisingEvents = $false
    $w2.EnableRaisingEvents = $false
    foreach ($s in $subs) {
        try { Unregister-Event -SourceIdentifier $s.Name -ErrorAction SilentlyContinue } catch {}
    }
    $w1.Dispose()
    $w2.Dispose()
    Write-Host ""
    Write-Host "  Watcher stopped." -ForegroundColor Green
    Write-Host ""
}
