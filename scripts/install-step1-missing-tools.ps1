$ErrorActionPreference = "Stop"

$requiredPackages = @(
    "docker-desktop",
    "kubernetes-cli",
    "k3d",
    "kubernetes-helm",
    "terraform",
    "awscli",
    "jq",
    "kubectx",
    "git"
)

function Test-IsAdmin {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    throw "Run this script in an elevated PowerShell session (Run as Administrator)."
}

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    throw "Chocolatey was not found. Install Chocolatey first."
}

Write-Host "Installing/ensuring required Step 1 packages..." -ForegroundColor Cyan
choco upgrade chocolatey -y
choco install $requiredPackages -y

Write-Host "Refreshing command environment..." -ForegroundColor Cyan
$refreshEnvBat = "$env:ChocolateyInstall\bin\RefreshEnv.cmd"
if (Test-Path $refreshEnvBat) {
    & $refreshEnvBat | Out-Null
}

Write-Host "Verifying versions..." -ForegroundColor Cyan
$checks = @(
    @{ Name = "git"; Cmd = { git --version } },
    @{ Name = "docker"; Cmd = { docker version } },
    @{ Name = "kubectl"; Cmd = { kubectl version --client } },
    @{ Name = "k3d"; Cmd = { k3d version } },
    @{ Name = "helm"; Cmd = { helm version } },
    @{ Name = "terraform"; Cmd = { terraform version } },
    @{ Name = "aws"; Cmd = { aws --version } },
    @{ Name = "jq"; Cmd = { jq --version } }
)

foreach ($check in $checks) {
    Write-Host "--- $($check.Name) ---" -ForegroundColor Yellow
    try {
        & $check.Cmd
    }
    catch {
        Write-Warning "Validation failed for $($check.Name): $($_.Exception.Message)"
    }
}

Write-Host "If Docker was just installed/updated, reboot Windows and open Docker Desktop once, then rerun docker checks." -ForegroundColor Green
