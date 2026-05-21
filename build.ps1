# build.ps1
# Bundle template.html + mermaid.min.js + fengshen-diagrams/*.mmd into mermaid-studio.html
# Portable: uses $PSScriptRoot, runs from anywhere (SVN/git checkout dir agnostic).
# Usage:  .\build.ps1     (from this folder)
#         powershell -ExecutionPolicy Bypass -File "<path>\build.ps1"

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$enc  = New-Object System.Text.UTF8Encoding($false)

$templatePath = Join-Path $root 'template.html'
$libPath      = Join-Path $root 'mermaid.min.js'
$outPath      = Join-Path $root 'mermaid-studio.html'
$diagDir      = Join-Path $root 'fengshen-diagrams'

$MERMAID_PLACEHOLDER  = '/*__MERMAID_LIB_INJECTION_POINT__*/'
$FENGSHEN_PLACEHOLDER = '/*__FENGSHEN_DIAGRAMS_INJECTION_POINT__*/'

if (-not (Test-Path $templatePath)) { throw "template.html not found at $templatePath" }
if (-not (Test-Path $libPath))      { throw "mermaid.min.js not found at $libPath" }

# 1. Read template + mermaid lib
$tmpl = [System.IO.File]::ReadAllText($templatePath, $enc)
$lib  = [System.IO.File]::ReadAllText($libPath, $enc)

if (-not $tmpl.Contains($MERMAID_PLACEHOLDER))  { throw "Mermaid placeholder not found in template.html" }
if (-not $tmpl.Contains($FENGSHEN_PLACEHOLDER)) { throw "Fengshen placeholder not found in template.html" }

# 2. Scan fengshen-diagrams/*.mmd
$items = New-Object System.Collections.Generic.List[Object]
if (Test-Path $diagDir) {
  $files = Get-ChildItem -Path $diagDir -Filter '*.mmd' -File -ErrorAction SilentlyContinue | Sort-Object Name
  foreach ($f in $files) {
    $code = [System.IO.File]::ReadAllText($f.FullName, $enc)
    $code = $code -replace "`r`n", "`n"
    $name = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
    $firstLine = ($code -split "`n", 2)[0].Trim()
    if ($firstLine -match '^%%\s*title\s*:\s*(.+?)\s*$') {
      $name = $Matches[1].Trim()
    }
    $items.Add([pscustomobject]@{ name = $name; code = $code }) | Out-Null
  }
}

# 3. Build JSON injection (one-by-one to guarantee array shape regardless of count)
$parts = @()
foreach ($it in $items) {
  $parts += (ConvertTo-Json -InputObject $it -Compress -Depth 10)
}
$json = '[' + ($parts -join ',') + ']'
$inject = "window.FENGSHEN_DIAGRAMS = $json;"

# 4. Replace placeholders (literal String.Replace, not regex)
$out = $tmpl.Replace($MERMAID_PLACEHOLDER,  $lib)
$out = $out.Replace($FENGSHEN_PLACEHOLDER, $inject)

# 5. Write final
[System.IO.File]::WriteAllText($outPath, $out, $enc)

# 6. Report
$size = (Get-Item $outPath).Length
$mb   = [math]::Round($size / 1MB, 2)
Write-Host ""
Write-Host ("  [OK] mermaid-studio.html  ({0} MB)" -f $mb) -ForegroundColor Green
Write-Host ("       bundled {0} fengshen diagram(s)" -f $items.Count) -ForegroundColor Green
foreach ($it in $items) {
  Write-Host ("         - " + $it.name) -ForegroundColor DarkGray
}
Write-Host ""
