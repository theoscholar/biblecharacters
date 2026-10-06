<#
    publish.ps1 - update the live Bible Characters site.

    Copies the study notes from "..\Character Study Notes" (the parent folder) into this folder
    under their published (clean, lowercase-hyphenated) names, then commits and
    pushes to GitHub. GitHub Pages redeploys in about a minute.

    Usage:
        .\publish.ps1
        .\publish.ps1 -Message "Add notes on Esther"
        .\publish.ps1 -WhatIf          # show what would change, push nothing

    Live site: https://theoscholar.github.io/biblecharacters/
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string] $Message = "Update study notes"
)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

$source  = Split-Path $PSScriptRoot -Parent          # ..\Character Study Notes
$mapFile = Join-Path $PSScriptRoot 'name-map.tsv'

if (-not (Test-Path -LiteralPath $source))  { throw "Source folder not found: $source" }
if (-not (Test-Path -LiteralPath $mapFile)) { throw "Name map not found: $mapFile" }

# ---- 0. Clear stale Git lock files ------------------------------------------
# Git leaves *.lock behind if a process is interrupted or lacks permission to
# clean up. If no git process is actually running, they are safe to remove.
if (-not (Get-Process -Name git -ErrorAction SilentlyContinue)) {
    $locks = @(
        Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '.git') -Filter '*.lock' -Recurse -Force -ErrorAction SilentlyContinue
    )
    if ($locks.Count -gt 0) {
        Write-Host "Clearing $($locks.Count) stale Git lock file(s)." -ForegroundColor DarkGray
        $locks | Remove-Item -Force -ErrorAction SilentlyContinue
    }

    $tmpObjects = @(
        Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '.git\objects') -Filter 'tmp_obj_*' -Recurse -Force -ErrorAction SilentlyContinue
    )
    if ($tmpObjects.Count -gt 0) {
        Write-Host "Clearing $($tmpObjects.Count) orphaned temp object(s)." -ForegroundColor DarkGray
        $tmpObjects | Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

# ---- 1. Load the original -> published filename map -------------------------
$map = @{}
foreach ($line in (Get-Content -LiteralPath $mapFile -Encoding UTF8)) {
    if ($line -match '^\s*(#|$)') { continue }
    $parts = $line -split "`t"
    if ($parts.Count -ne 2) { throw "Malformed line in name-map.tsv: $line" }
    $map[$parts[0].Trim()] = $parts[1].Trim()
}
Write-Host "Loaded $($map.Count) filename mappings." -ForegroundColor DarkGray

# ---- 2. Warn about originals that have no mapping ---------------------------
# Only the top level of "Character Study Notes" is considered; subfolders are ignored.
$missing = Get-ChildItem -LiteralPath $source -Filter *.html |
    Where-Object { -not $map.ContainsKey($_.Name) }

if ($missing) {
    Write-Host ""
    Write-Warning "These files in 'Character Study Notes' have no entry in name-map.tsv and will NOT be published:"
    $missing | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor Yellow }
    Write-Host "  Add a line to name-map.tsv (original<TAB>published-name.html) to include them," -ForegroundColor Yellow
    Write-Host "  and remember to add a card on index.html too." -ForegroundColor Yellow
    Write-Host ""
}

# ---- 3. Copy changed files into the working copy ----------------------------
$copied = 0
foreach ($entry in $map.GetEnumerator()) {
    $from = Join-Path $source $entry.Key
    $to   = Join-Path $PSScriptRoot $entry.Value

    if (-not (Test-Path -LiteralPath $from)) {
        Write-Warning "Missing original, skipped: $($entry.Key)"
        continue
    }

    $same = (Test-Path -LiteralPath $to) -and
            ((Get-FileHash -LiteralPath $from).Hash -eq (Get-FileHash -LiteralPath $to).Hash)

    if (-not $same) {
        Copy-Item -LiteralPath $from -Destination $to -Force
        Write-Host "  updated  $($entry.Value)" -ForegroundColor Cyan
        $copied++
    }
}
Write-Host "$copied file(s) refreshed from the originals." -ForegroundColor DarkGray

# ---- 4. Guard: every published page must carry the noindex tag --------------
$unprotected = Get-ChildItem -LiteralPath $PSScriptRoot -Filter *.html |
    Where-Object { (Get-Content -LiteralPath $_.FullName -Raw) -notmatch 'name="robots"' }

if ($unprotected) {
    Write-Warning "These pages are MISSING the noindex tag and would be visible to search engines:"
    $unprotected | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor Yellow }
    Write-Host '  Add <meta name="robots" content="noindex, nofollow"> just after <head>.' -ForegroundColor Yellow
    Write-Host ""
}

# ---- 5. Commit and push -----------------------------------------------------
$dirty = git status --porcelain
if (-not $dirty) {
    Write-Host "`nNothing to publish - the live site already matches your files." -ForegroundColor Green
    exit 0
}

Write-Host "`nPending changes:" -ForegroundColor White
git status --short

if ($WhatIfPreference) {
    Write-Host "`n-WhatIf specified. Nothing was committed or pushed." -ForegroundColor Yellow
    exit 0
}

git add -A
git commit -m $Message
if ($LASTEXITCODE -ne 0) { throw "git commit failed." }

git push -u origin main
if ($LASTEXITCODE -ne 0) { throw "git push failed. If this is an auth error, see README-publishing.md." }

Write-Host "`nPushed. GitHub Pages usually redeploys within a minute:" -ForegroundColor Green
Write-Host "  https://theoscholar.github.io/biblecharacters/" -ForegroundColor Green
