[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ClusterName = "devops-lab-local"
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

Step "Pre-checks"
if (-not (Get-Command k3d -ErrorAction SilentlyContinue)) {
    throw "Required command not found: k3d"
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Warn "Docker command not found. Trying to stop k3d cluster anyway."
}

Step "Current cluster status"
k3d cluster list

Step "Stopping cluster"
if ($PSCmdlet.ShouldProcess("k3d cluster '$ClusterName'", "stop")) {
    k3d cluster stop $ClusterName | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to stop cluster '$ClusterName'"
    }
    Info "Cluster '$ClusterName' stopped"
}

Step "Post-check"
k3d cluster list

Write-Host "`nDone. To start again use: .\\scripts\\start-lab.ps1" -ForegroundColor Green
