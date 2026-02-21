[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string[]]$Applications = @(
        "devops-lab-app-prod-blue",
        "devops-lab-app-prod-green",
        "devops-lab-shared-db-prod"
    ),
    [string]$Namespace = "argocd",
    [string]$TargetRevision = "main"
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

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    throw "Required command not found: kubectl"
}

Step "Enforce Argo targetRevision=$TargetRevision"

$patchFile = Join-Path $env:TEMP ("argocd-target-revision-{0}.json" -f [guid]::NewGuid().ToString())
$patchJson = '{"spec":{"source":{"targetRevision":"' + $TargetRevision + '"}}}'
$patchJson | Set-Content -Path $patchFile -Encoding utf8

try {
    foreach ($app in $Applications) {
        kubectl -n $Namespace get application $app | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Warn "Application not found: $Namespace/$app"
            continue
        }

        $currentRevision = (kubectl -n $Namespace get application $app -o jsonpath='{.spec.source.targetRevision}').Trim()
        if ($currentRevision -eq $TargetRevision) {
            Info "$app already points to '$TargetRevision'"
            continue
        }

        if ($PSCmdlet.ShouldProcess("$Namespace/$app", "set targetRevision to '$TargetRevision'")) {
            kubectl -n $Namespace patch application $app --type merge --patch-file $patchFile | Out-Null
            kubectl -n $Namespace annotate application $app argocd.argoproj.io/refresh=hard --overwrite | Out-Null
            Info "$app updated: $currentRevision -> $TargetRevision"
        }
    }
}
finally {
    Remove-Item -Path $patchFile -Force -ErrorAction SilentlyContinue
}

Step "Current application state"
kubectl -n $Namespace get applications $Applications -o custom-columns=NAME:.metadata.name,TARGET:.spec.source.targetRevision,SYNC:.status.sync.status,HEALTH:.status.health.status
