[CmdletBinding()]
param(
    [string]$Node = 'mainland-local',
    [switch]$NoPush,
    [switch]$RunCi,
    [switch]$CheckOnly,
    [switch]$AllowNonMainland,
    [string]$Python,
    [string]$Ffprobe,
    [string]$Ffmpeg,
    [string]$Message = 'chore: refresh playlists from mainland local node'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot
Set-Location $RepoRoot

function Write-Step {
    param([string]$Text)
    Write-Host ""
    Write-Host "==> $Text" -ForegroundColor Cyan
}

function Invoke-Native {
    param(
        [string]$FilePath,
        [string[]]$Arguments
    )
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $FilePath $($Arguments -join ' ')"
    }
}

function Test-Python {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path $Path)) { return $false }
    try {
        $output = & $Path --version 2>&1
        if ($LASTEXITCODE -ne 0) { return $false }
        $match = [regex]::Match(($output | Out-String), 'Python 3\.(\d+)')
        return ($match.Success -and [int]$match.Groups[1].Value -ge 10)
    }
    catch {
        return $false
    }
}

function Resolve-Python {
    param([string]$Explicit)
    $candidates = New-Object 'System.Collections.Generic.List[string]'
    if ($Explicit) { $candidates.Add($Explicit) }
    if ($env:APTV_PYTHON) { $candidates.Add($env:APTV_PYTHON) }

    $uvDir = Join-Path $env:USERPROFILE '.local\bin'
    if (Test-Path $uvDir) {
        Get-ChildItem $uvDir -Filter 'python3*.exe' -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            ForEach-Object { $candidates.Add($_.FullName) }
    }

    foreach ($name in @('python3', 'python')) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command -and $command.Source) { $candidates.Add($command.Source) }
    }

    foreach ($candidate in $candidates) {
        if (Test-Python $candidate) {
            return (Resolve-Path $candidate).Path
        }
    }
    throw 'Python 3.10+ not found. Set APTV_PYTHON or pass -Python <path>.'
}

function Resolve-Tool {
    param(
        [string]$Name,
        [string]$Explicit,
        [string[]]$Candidates
    )
    if ($Explicit) {
        if (-not (Test-Path $Explicit)) { throw "$Name not found: $Explicit" }
        return (Resolve-Path $Explicit).Path
    }

    $envName = 'APTV_' + $Name.ToUpperInvariant()
    $fromEnv = [Environment]::GetEnvironmentVariable($envName)
    if ($fromEnv) {
        if (-not (Test-Path $fromEnv)) { throw "$Name not found: $fromEnv" }
        return (Resolve-Path $fromEnv).Path
    }

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command -and $command.Source -and (Test-Path $command.Source)) {
        return $command.Source
    }

    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return (Resolve-Path $candidate).Path
        }
    }
    throw "$Name not found. Install it or pass an explicit path."
}

$ffprobeCandidates = @(
    'D:\LiaoZC\tools\ffprobe\ffprobe.exe',
    'D:\Program Files\FFmpeg\bin\ffprobe.exe',
    'C:\ffmpeg\bin\ffprobe.exe'
)
$ffmpegCandidates = @(
    'D:\Program Files\FFmpeg\bin\ffmpeg.exe',
    'C:\ffmpeg\bin\ffmpeg.exe'
)

$Python = Resolve-Python -Explicit $Python
$Ffprobe = Resolve-Tool -Name 'ffprobe' -Explicit $Ffprobe -Candidates $ffprobeCandidates
$Ffmpeg = Resolve-Tool -Name 'ffmpeg' -Explicit $Ffmpeg -Candidates $ffmpegCandidates

$toolDirs = @((Split-Path -Parent $Ffprobe), (Split-Path -Parent $Ffmpeg))
$pathParts = @($toolDirs) + ($env:PATH -split ';')
$env:PATH = (@($pathParts | Where-Object { $_ } | Select-Object -Unique) -join ';')

& $Ffprobe -version *> $null
if ($LASTEXITCODE -ne 0) { throw "ffprobe failed to start: $Ffprobe" }
& $Ffmpeg -version *> $null
if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed to start: $Ffmpeg" }

Write-Host "Python : $Python"
Write-Host "ffprobe: $Ffprobe"
Write-Host "ffmpeg : $Ffmpeg"

Write-Step 'Checking egress IP'
$isMainland = $false
try {
    $ipInfo = Invoke-RestMethod -Uri 'https://myip.ipip.net' -TimeoutSec 10
    Write-Host "Egress: $ipInfo"
    # Use code points to avoid Windows PowerShell 5.1 misreading UTF-8 literals.
    $mainland = [string]([char]0x4E2D) + [char]0x56FD
    $excluded = ([string]([char]0x9999) + [char]0x6E2F) + '|' + ([string]([char]0x6FB3) + [char]0x95E8) + '|' + ([string]([char]0x53F0) + [char]0x6E7E)
    $isMainland = ($ipInfo -match $mainland) -and ($ipInfo -notmatch $excluded)
    if (-not $isMainland) {
        Write-Warning 'Egress IP is not mainland China. Disable VPN/proxy before validating.'
    }
}
catch {
    Write-Warning "Cannot query egress IP: $($_.Exception.Message)"
}

if (-not $isMainland -and -not $AllowNonMainland) {
    Write-Host 'ERROR: Egress IP is not verified as mainland China. Disable VPN/proxy, or pass -AllowNonMainland to override.' -ForegroundColor Red
    exit 1
}

if ($CheckOnly) {
    Write-Step 'Check only; exiting without running the update.'
    exit 0
}

Write-Step 'Running unit tests'
Invoke-Native $Python @('-m', 'unittest', 'discover', '-s', 'scripts', '-p', 'test_*.py')

Write-Step 'Syncing Guovin candidates'
Invoke-Native $Python @('scripts/sync_guovin.py')

Write-Step "Probing and generating playlists (node=$Node); this may take several minutes"
Invoke-Native $Python @('scripts/build_playlist.py', '--node', $Node)

Write-Step 'Updating README timestamps'
try {
    Invoke-Native $Python @('scripts/update_readme_timestamps.py')
}
catch {
    Write-Warning "README timestamp update failed: $($_.Exception.Message)"
}

Write-Step 'Result summary'
$report = Get-Content (Join-Path $RepoRoot 'reports/latest.json') -Raw | ConvertFrom-Json
$enabled = @(Select-String -Path (Join-Path $RepoRoot 'IPTV_ALL.m3u') -Pattern '^#EXTINF').Count
Write-Host ("node={0} generated_at={1}" -f $report.node, $report.generated_at)
Write-Host ("channels={0} disabled={1} IPTV_ALL_enabled={2}" -f $report.channel_count, $report.disabled_channel_count, $enabled)

if ($NoPush) {
    Write-Step 'Skipping commit and push (-NoPush)'
    exit 0
}

Write-Step 'Staging generated files'
$outputs = @(
    'README.md',
    'IPTV_ALL.m3u',
    'IPTV_ADULT.m3u',
    'data/history.json',
    'reports/latest.json',
    'reports/upstream-merge.json',
    'sources/guovin-iptv-api.m3u'
)
$existing = @($outputs | Where-Object { Test-Path (Join-Path $RepoRoot $_) })
Invoke-Native 'git' (@('add', '--') + $existing)

$staged = @(& git diff --cached --name-only)
if ($staged.Count -eq 0) {
    Write-Host 'No generated changes to commit.'
    exit 0
}
Write-Host ($staged -join "`n")

Write-Step 'Committing changes'
$commitArgs = @('commit', '-m', $Message)
if (-not $RunCi) { $commitArgs += @('-m', '[skip ci]') }
Invoke-Native 'git' $commitArgs

Write-Step 'Rebasing on origin/main'
Invoke-Native 'git' @('pull', '--rebase', 'origin', 'main')

Write-Step 'Pushing to origin/main'
$gh = $null
$ghCommand = Get-Command gh -ErrorAction SilentlyContinue
if ($ghCommand -and $ghCommand.Source) {
    $gh = $ghCommand.Source
}
else {
    $ghCandidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\GitHubCLI\bin\gh.exe'),
        'C:\Program Files\GitHub CLI\gh.exe'
    )
    $gh = $ghCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}

$pushed = $false
if ($gh) {
    $ghPath = $gh -replace '\\', '/'
    $helper = "credential.https://github.com.helper=!$ghPath auth git-credential"
    try {
        Invoke-Native 'git' @('-c', 'credential.https://github.com.helper=', '-c', $helper, 'push', 'origin', 'main')
        $pushed = $true
    }
    catch {
        Write-Warning "Push with gh credential helper failed: $($_.Exception.Message)"
    }
}
if (-not $pushed) {
    Invoke-Native 'git' @('push', 'origin', 'main')
}

Write-Step 'Done'
& git status --short --branch
& git log -1 --oneline