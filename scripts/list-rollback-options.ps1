[CmdletBinding()]
param(
    [string]$Environment = "staging",
    [int]$Count = 5,
    [string]$DeployRepoPath,
    [switch]$SyncDeployRepo,
    [switch]$IncludeCurrent
)

$ErrorActionPreference = "Stop"

function Step([string]$message) {
    Write-Host "`n=== $message ===" -ForegroundColor Cyan
}

function Info([string]$message) {
    Write-Host "[OK] $message" -ForegroundColor Green
}

function Warn([string]$message) {
    Write-Host "[WARN] $message" -ForegroundColor Yellow
}

function Get-DefaultDeployRepoPath {
    $candidate = Join-Path $PSScriptRoot "..\..\..\deploy\devops-lab-deploy"
    if (Test-Path $candidate) {
        return (Resolve-Path $candidate).Path
    }
    return $null
}

function Get-TagFromContent([string]$content) {
    $match = [regex]::Match($content, '(?m)^\s*newTag:\s*"?([^"\r\n]+)"?\s*$')
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }
    return ""
}

function Sync-Repo([string]$path) {
    Step "Sync deploy repo"
    try {
        $dirty = git -C $path status --porcelain
        if ($dirty) {
            Warn "Deploy repo has local changes; skipping pull"
            git -C $path fetch origin | Out-Null
            return
        }
        git -C $path fetch origin | Out-Null
        git -C $path pull --ff-only | Out-Null
        Info "Deploy repo synced"
    } catch {
        Warn "Could not sync deploy repo: $($_.Exception.Message)"
    }
}

if (-not $DeployRepoPath) {
    $DeployRepoPath = Get-DefaultDeployRepoPath
}

if (-not $DeployRepoPath -or -not (Test-Path $DeployRepoPath)) {
    throw "Deploy repo not found. Use -DeployRepoPath pointing to devops-lab-deploy."
}

$DeployRepoPath = (Resolve-Path $DeployRepoPath).Path

if ($SyncDeployRepo) {
    Sync-Repo -path $DeployRepoPath
}

$allowed = @("dev", "staging", "prod-blue", "prod-green")
if ($Environment -notin $allowed) {
    throw "Invalid environment '$Environment'. Allowed: $($allowed -join ', ')"
}

$target = "apps/devops-lab-app/overlays/$Environment/kustomization.yaml"
$targetPath = Join-Path $DeployRepoPath $target
if (-not (Test-Path $targetPath)) {
    throw "Overlay not found: $targetPath"
}

Step "Rollback options for $Environment"
Info "Deploy repo: $DeployRepoPath"

$currentContent = Get-Content -Path $targetPath -Raw -Encoding UTF8
$currentTag = Get-TagFromContent -content $currentContent
if (-not $currentTag) {
    throw "Could not read current newTag from $target"
}

Write-Host "Current tag: $currentTag"

$tags = New-Object System.Collections.Generic.List[string]
$commits = git -C $DeployRepoPath log --format=%H -- $target
foreach ($commit in $commits) {
    $content = git -C $DeployRepoPath show "${commit}:${target}" 2>$null
    if (-not $content) {
        continue
    }
    $tag = Get-TagFromContent -content ($content -join "`n")
    if (-not $tag) {
        continue
    }
    if (-not $IncludeCurrent -and $tag -eq $currentTag) {
        continue
    }
    if (-not $tags.Contains($tag)) {
        $tags.Add($tag)
    }
    if ($tags.Count -ge $Count) {
        break
    }
}

if ($tags.Count -eq 0) {
    Warn "No rollback candidates found."
    exit 1
}

Write-Host "`nSuggested rollback tags (copy one to the issue):"
for ($i = 0; $i -lt $tags.Count; $i++) {
    $index = $i + 1
    Write-Host ("{0}. {1}" -f $index, $tags[$i])
}

Write-Host "`nRecommended now: $($tags[0])" -ForegroundColor Green