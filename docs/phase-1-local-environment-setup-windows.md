# Phase 1 — Local Environment Setup (Windows)

## Objective

Prepare a Windows workstation for the DevOps Hybrid Lab with all required tooling for local Kubernetes, containerization, IaC, and cloud integration.

## Scope

This phase installs and validates:

- Git
- Docker Desktop
- kubectl
- k3d
- Helm
- Terraform
- AWS CLI
- jq
- kubectx (optional)

## Prerequisites

- Windows 10/11 (Pro, Enterprise, Education recommended)
- Administrator PowerShell session
- Virtualization enabled in BIOS/UEFI
- Internet access to package repositories

## Execution Steps

### 1) Validate OS and virtualization prerequisites

```powershell
winver
systeminfo | Select-String -Pattern "Hyper-V Requirements"
```

Expected outcome:

- Supported Windows edition/version
- Virtualization flags available/enabled

### 2) Install Chocolatey (if not installed)

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; `
[System.Net.ServicePointManager]::SecurityProtocol = `
[System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

Verify:

```powershell
choco --version
```

### 3) Install required tools

```powershell
choco upgrade chocolatey -y
choco install git -y
choco install docker-desktop -y
choco install kubernetes-cli -y
choco install k3d -y
choco install kubernetes-helm -y
choco install terraform -y
choco install awscli -y
choco install jq -y
choco install kubectx -y
```

### 4) Restart and initialize Docker Desktop

- Restart Windows after Docker Desktop installation.
- Open Docker Desktop manually.
- Wait until status is **Docker is running**.

### 5) Validate all installed tooling

Run in a new PowerShell session:

```powershell
git --version
docker version
docker ps
kubectl version --client
k3d version
helm version
terraform version
aws --version
jq --version
```

Expected outcome:

- All commands return valid version/response output
- Docker daemon responds correctly

## Definition of Done (DoD)

Phase 1 is complete when:

- All required tools are installed
- Validation commands pass in a fresh terminal session
- Docker Desktop is operational
- Environment is ready for Phase 2 (local Kubernetes cluster creation)

## Troubleshooting Notes

- If Docker fails to start, verify WSL2/Hyper-V status and reboot again.
- If `choco` is not recognized, close and reopen terminal.
- If corporate proxy is in use, configure Chocolatey and Docker proxy settings before install.

## Next Step

Proceed to **Phase 2 — Create Local Kubernetes Cluster (k3d)**.
