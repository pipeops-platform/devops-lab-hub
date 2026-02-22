[CmdletBinding()]
param(
    [string]$DeployRepoPath,
    [string[]]$Environments = @("dev", "staging", "prod-blue", "prod-green"),
    [switch]$SyncDeployRepo,
    [switch]$IncludeHistory,
    [int]$HistoryCount = 5
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

function Get-OverlayInfo([string]$basePath, [string]$environment) {
    $overlayFile = Join-Path $basePath "apps/devops-lab-app/overlays/$environment/kustomization.yaml"
    if (-not (Test-Path $overlayFile)) {
        return $null
    }

    $content = Get-Content -Path $overlayFile -Raw -Encoding UTF8
    $namespaceMatch = [regex]::Match($content, '(?m)^\s*namespace:\s*(.+)\s*$')
    $newNameMatch = [regex]::Match($content, '(?m)^\s*newName:\s*(.+)\s*$')
    $newTagMatch = [regex]::Match($content, '(?m)^\s*newTag:\s*"?([^"\r\n]+)"?\s*$')

    $namespace = if ($namespaceMatch.Success) { $namespaceMatch.Groups[1].Value.Trim() } else { "" }
    $imageRepo = if ($newNameMatch.Success) { $newNameMatch.Groups[1].Value.Trim() } else { "" }
    $desiredTag = if ($newTagMatch.Success) { $newTagMatch.Groups[1].Value.Trim() } else { "" }

    $lastChange = ""
    try {
        $lastChange = (git -C $basePath log -1 --date=iso --pretty=format:"%h | %ad | %an" -- "apps/devops-lab-app/overlays/$environment/kustomization.yaml")
    } catch {
        $lastChange = "n/a"
    }

    return [pscustomobject]@{
        Environment = $environment
        Namespace = $namespace
        ImageRepo = $imageRepo
        DesiredTag = $desiredTag
        OverlayFile = $overlayFile
        LastChange = $lastChange
    }
}

function Get-RunningImageInfo([string]$namespace) {
    $result = [pscustomobject]@{
        RunningImage = "n/a"
        RunningTag = "n/a"
        RunningState = "unknown"
    }

    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        $result.RunningState = "kubectl-not-found"
        return $result
    }

    try {
        $image = kubectl -n $namespace get deployment devops-lab-app -o jsonpath='{.spec.template.spec.containers[0].image}' 2>$null
        if (-not $image) {
            $result.RunningState = "deployment-not-found"
            return $result
        }

        $runningTag = ""
        if ($image -match ':(?<tag>[^:@]+)$') {
            $runningTag = $Matches['tag']
        } elseif ($image -match '@(?<digest>sha256:[0-9a-f]+)$') {
            $runningTag = $Matches['digest']
        }

        $result.RunningImage = $image
        $result.RunningTag = if ($runningTag) { $runningTag } else { "n/a" }
        $result.RunningState = "ok"
        return $result
    } catch {
        $result.RunningState = "query-failed"
        return $result
    }
}

function Get-ArgoAppStatus([string]$namespace) {
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        return [pscustomobject]@{ Name = "n/a"; Sync = "n/a"; Health = "n/a" }
    }

    try {
        $apps = kubectl -n argocd get applications -o json 2>$null | ConvertFrom-Json
        if (-not $apps.items) {
            return [pscustomobject]@{ Name = "n/a"; Sync = "n/a"; Health = "n/a" }
        }

        $app = $apps.items |
            Where-Object { $_.spec.destination.namespace -eq $namespace } |
            Select-Object -First 1

        if (-not $app) {
            return [pscustomobject]@{ Name = "n/a"; Sync = "n/a"; Health = "n/a" }
        }

        return [pscustomobject]@{
            Name = $app.metadata.name
            Sync = $app.status.sync.status
            Health = $app.status.health.status
        }
    } catch {
        return [pscustomobject]@{ Name = "n/a"; Sync = "n/a"; Health = "n/a" }
    }
}

function Get-TagHistory([string]$basePath, [string]$environment, [int]$count) {
    $target = "apps/devops-lab-app/overlays/$environment/kustomization.yaml"
    $tags = New-Object System.Collections.Generic.List[string]

    try {
        $commits = git -C $basePath log --format=%H -- $target
        foreach ($commit in $commits) {
            $content = git -C $basePath show "${commit}:${target}" 2>$null
            if (-not $content) {
                continue
            }
            $match = [regex]::Match(($content -join "`n"), '(?m)^\s*newTag:\s*"?([^"\r\n]+)"?\s*$')
            if (-not $match.Success) {
                continue
            }
            $tag = $match.Groups[1].Value.Trim()
            if ($tag -and -not $tags.Contains($tag)) {
                $tags.Add($tag)
            }
            if ($tags.Count -ge $count) {
                break
            }
        }
    } catch {
        return "n/a"
    }

    if ($tags.Count -eq 0) {
        return "n/a"
    }
    return ($tags -join ", ")
}

function Sync-DeployRepo([string]$basePath) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Warn "git not found; skipping deploy repo sync"
        return
    }

    Step "Sync deploy repo"
    try {
        $localHead = (git -C $basePath rev-parse --short HEAD).Trim()
        Info "Current local HEAD: $localHead"

        $dirty = (git -C $basePath status --porcelain)
        if ($dirty) {
            Warn "Deploy repo has uncommitted changes; skipping pull to avoid conflicts"
            git -C $basePath fetch origin | Out-Null
            $remoteHead = (git -C $basePath rev-parse --short origin/main).Trim()
            Info "Fetched origin/main: $remoteHead"
            return
        }

        git -C $basePath fetch origin | Out-Null
        $remoteHeadBeforePull = (git -C $basePath rev-parse --short origin/main).Trim()
        Info "Fetched origin/main: $remoteHeadBeforePull"

        git -C $basePath pull --ff-only | Out-Null
        $localHeadAfterPull = (git -C $basePath rev-parse --short HEAD).Trim()
        Info "Local HEAD after sync: $localHeadAfterPull"
    } catch {
        Warn "Could not fully sync deploy repo: $($_.Exception.Message)"
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
    Sync-DeployRepo -basePath $DeployRepoPath
}

Step "Collecting desired and running versions"
Info "Deploy repo: $DeployRepoPath"

$rows = New-Object System.Collections.Generic.List[object]

foreach ($environment in $Environments) {
    $overlay = Get-OverlayInfo -basePath $DeployRepoPath -environment $environment
    if (-not $overlay) {
        Warn "Overlay not found for environment '$environment'"
        continue
    }

    $running = Get-RunningImageInfo -namespace $overlay.Namespace
    $argo = Get-ArgoAppStatus -namespace $overlay.Namespace

    $inSync = "unknown"
    if ($overlay.DesiredTag -and $running.RunningTag -and $running.RunningTag -ne "n/a") {
        $inSync = if ($overlay.DesiredTag -eq $running.RunningTag) { "yes" } else { "no" }
    }

    $history = ""
    if ($IncludeHistory) {
        $history = Get-TagHistory -basePath $DeployRepoPath -environment $environment -count $HistoryCount
    }

    $rows.Add([pscustomobject]@{
        Environment = $overlay.Environment
        Namespace = $overlay.Namespace
        DesiredTag = $overlay.DesiredTag
        RunningTag = $running.RunningTag
        InSync = $inSync
        ArgoSync = $argo.Sync
        ArgoHealth = $argo.Health
        ArgoApp = $argo.Name
        LastOverlayChange = $overlay.LastChange
        RecentTags = $history
    }) | Out-Null
}

if ($rows.Count -eq 0) {
    Warn "No environments were processed."
    exit 1
}

$mismatchCount = ($rows | Where-Object { $_.InSync -eq "no" }).Count

Step "Environment version report"
if ($IncludeHistory) {
    $rows |
        Select-Object Environment, Namespace, DesiredTag, RunningTag, InSync, ArgoSync, ArgoHealth, ArgoApp, LastOverlayChange, RecentTags |
        Format-Table -AutoSize
} else {
    $rows |
        Select-Object Environment, Namespace, DesiredTag, RunningTag, InSync, ArgoSync, ArgoHealth, ArgoApp, LastOverlayChange |
        Format-Table -AutoSize
}

Step "Summary"
if ($mismatchCount -gt 0) {
    Warn "$mismatchCount environment(s) are not aligned between desired tag and running tag"
} else {
    Info "All inspected environments are aligned"
}

Write-Host "Tip: rerun with -IncludeHistory to display recent tags per environment for rollback/audit context."
Write-Host "Tip: use -SyncDeployRepo to update local deploy repo before generating the report."