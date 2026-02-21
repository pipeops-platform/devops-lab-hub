param(
    [string]$ClusterName = "devops-lab-local",
    [switch]$SkipArgoRepair,
    [switch]$SkipTargetRevisionEnforce
)

$ErrorActionPreference = "Stop"

function Step([string]$message) {
    Write-Host "`n=== $message ===" -ForegroundColor Cyan
}

function Warn([string]$message) {
    Write-Host "[WARN] $message" -ForegroundColor Yellow
}

function Info([string]$message) {
    Write-Host "[OK] $message" -ForegroundColor Green
}

Step "Pre-checks"
$requiredCommands = @("docker", "k3d", "kubectl", "curl.exe")
foreach ($command in $requiredCommands) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $command"
    }
}
Info "Required commands available"

Step "Docker status"
docker ps --format "{{.ID}}" | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Docker Desktop is not running. Start Docker Desktop and try again."
}
Info "Docker is running"

Step "Cluster startup"
k3d cluster start $ClusterName | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Failed to start cluster '$ClusterName'"
}
Info "Cluster '$ClusterName' is running"

Step "kubectl context"
$context = "k3d-$ClusterName"
kubectl config use-context $context | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Failed to switch kubectl context to '$context'"
}
Info "Using context '$context'"

Step "Node health"
kubectl get nodes

Step "ArgoCD core health"
$argocdPods = kubectl -n argocd get pods -o json | ConvertFrom-Json
$argocdPods.items | ForEach-Object {
    Write-Host ("- {0}: ready={1}, phase={2}" -f $_.metadata.name, $_.status.containerStatuses[0].ready, $_.status.phase)
}

Step "ArgoCD applications"
$appsJson = kubectl -n argocd get applications -o json | ConvertFrom-Json
$needsRepair = $false
$needsCoreRepair = $false

foreach ($pod in $argocdPods.items) {
    $phase = $pod.status.phase
    $ready = $false
    if ($pod.status.containerStatuses -and $pod.status.containerStatuses.Count -gt 0) {
        $ready = $pod.status.containerStatuses[0].ready
    }
    if ($phase -ne "Running" -or -not $ready) {
        $needsCoreRepair = $true
    }
}

if ($appsJson.items.Count -eq 0) {
    Warn "No ArgoCD applications found in namespace argocd"
} else {
    foreach ($app in $appsJson.items) {
        $sync = $app.status.sync.status
        $health = $app.status.health.status
        Write-Host ("- {0}: sync={1}, health={2}" -f $app.metadata.name, $sync, $health)
        if ($sync -eq "Unknown" -or $health -ne "Healthy") {
            $needsRepair = $true
        }
    }
}

if (-not $SkipArgoRepair -and $needsRepair) {
    Step "ArgoCD auto-repair (repo-server + refresh)"
    kubectl -n argocd rollout restart deployment argocd-repo-server | Out-Null
    kubectl -n argocd rollout status deployment argocd-repo-server --timeout=180s | Out-Null
    $appNames = kubectl -n argocd get applications -o jsonpath='{.items[*].metadata.name}'
    foreach ($appName in $appNames.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)) {
        kubectl -n argocd annotate application $appName argocd.argoproj.io/refresh=hard --overwrite | Out-Null
    }
    Start-Sleep -Seconds 8
    Info "ArgoCD repair completed"
}

if (-not $SkipArgoRepair -and $needsCoreRepair) {
    Step "ArgoCD core auto-repair"
    kubectl -n argocd rollout restart deployment argocd-applicationset-controller | Out-Null
    kubectl -n argocd rollout status deployment argocd-applicationset-controller --timeout=180s | Out-Null
    kubectl -n argocd rollout restart deployment argocd-repo-server | Out-Null
    kubectl -n argocd rollout status deployment argocd-repo-server --timeout=180s | Out-Null
    Info "ArgoCD core repair completed"
}

if (-not $SkipTargetRevisionEnforce) {
    Step "Argo targetRevision guard (prod apps => main)"
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $guardScript = Join-Path $scriptDir "ensure-argocd-main-target.ps1"
    if (Test-Path $guardScript) {
        powershell -ExecutionPolicy Bypass -File $guardScript
    } else {
        Warn "Guard script not found: $guardScript"
    }
}

Step "Ingress endpoint checks"
$argoStatus = curl.exe -s -o NUL -w "%{http_code}" -H "Host: argocd.localtest.me" http://127.0.0.1/api/version
Write-Host "- Argo endpoint http://argocd.localtest.me/api/version => $argoStatus"

$devStatus = curl.exe -s -o NUL -w "%{http_code}" -H "Host: devops-lab-app-dev.localtest.me" http://127.0.0.1/health
$stagingStatus = curl.exe -s -o NUL -w "%{http_code}" -H "Host: devops-lab-app-staging.localtest.me" http://127.0.0.1/health
$prodBlueStatus = curl.exe -s -o NUL -w "%{http_code}" -H "Host: devops-lab-app-prod-blue.localtest.me" http://127.0.0.1/health
$prodGreenStatus = curl.exe -s -o NUL -w "%{http_code}" -H "Host: devops-lab-app-prod-green.localtest.me" http://127.0.0.1/health
Write-Host "- App health dev=$devStatus staging=$stagingStatus prod-blue=$prodBlueStatus prod-green=$prodGreenStatus"

Step "Final summary"
Write-Host "Argo URL: http://argocd.localtest.me" -ForegroundColor Green
Write-Host "Tip: run '.\\scripts\\start-lab.ps1 -SkipArgoRepair' for a faster boot when everything is already healthy."
