param(
    [string]$Owner = "flaviopiccolo-boop",
    [string[]]$Repositories = @(
        "devops-lab-hub",
        "devops-lab-app",
        "devops-lab-deploy",
        "devops-lab-infra"
    ),
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$script:GhCliPath = $null

function Get-GhCliPath {
    $command = Get-Command gh -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $candidates = @(
        "$env:ProgramFiles\GitHub CLI\gh.exe",
        "$env:LOCALAPPDATA\Programs\GitHub CLI\gh.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

function Invoke-Gh {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    & $script:GhCliPath @Arguments
    return $LASTEXITCODE
}

function Assert-GhCli {
    $script:GhCliPath = Get-GhCliPath
    if (-not $script:GhCliPath) {
        throw "GitHub CLI (gh) is not installed. Install gh and authenticate with 'gh auth login'."
    }

    Invoke-Gh auth status | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub CLI is not authenticated. Run 'gh auth login' and retry."
    }
}

function Set-Label {
    param(
        [string]$Repo,
        [string]$Name,
        [string]$Color,
        [string]$Description
    )

    if ($DryRun) {
        Write-Host "[DryRun] Would create/update label '$Name' in $Repo" -ForegroundColor Yellow
        return
    }

    Invoke-Gh label create $Name --repo $Repo --color $Color --description $Description --force | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create/update label '$Name' in $Repo"
    }
}

function Set-Milestone {
    param(
        [string]$Repo,
        [string]$Title
    )

    $existingTitles = Invoke-Gh api "repos/$Repo/milestones?state=all&per_page=100" --jq ".[].title"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to list milestones in $Repo"
    }

    $milestoneExists = @($existingTitles) -contains $Title

    if (-not $milestoneExists) {
        if ($DryRun) {
            Write-Host "[DryRun] Would create milestone '$Title' in $Repo" -ForegroundColor Yellow
            return
        }

        Invoke-Gh api "repos/$Repo/milestones" --method POST --field ("title={0}" -f $Title) | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create milestone '$Title' in $Repo"
        }
    }
    elseif ($DryRun) {
        Write-Host "[DryRun] Milestone '$Title' already exists in $Repo" -ForegroundColor DarkYellow
    }
}

$labels = @(
    @{ Name = "bug"; Color = "d73a4a"; Description = "Defect or incorrect behavior" },
    @{ Name = "enhancement"; Color = "a2eeef"; Description = "New feature or improvement" },
    @{ Name = "task"; Color = "0e8a16"; Description = "Planned technical activity" },
    @{ Name = "docs"; Color = "0075ca"; Description = "Documentation-only work" },
    @{ Name = "chore"; Color = "cfd3d7"; Description = "Maintenance and housekeeping" },

    @{ Name = "priority:low"; Color = "c2e0c6"; Description = "Low priority" },
    @{ Name = "priority:medium"; Color = "fbca04"; Description = "Medium priority" },
    @{ Name = "priority:high"; Color = "f9d0c4"; Description = "High priority" },
    @{ Name = "priority:critical"; Color = "b60205"; Description = "Critical priority" },

    @{ Name = "status:triage"; Color = "ededed"; Description = "Awaiting triage" },
    @{ Name = "status:ready"; Color = "0e8a16"; Description = "Ready for execution" },
    @{ Name = "status:in-progress"; Color = "1d76db"; Description = "Work in progress" },
    @{ Name = "status:blocked"; Color = "b60205"; Description = "Blocked by dependency" },
    @{ Name = "status:review"; Color = "5319e7"; Description = "In review" },
    @{ Name = "status:done"; Color = "0e8a16"; Description = "Completed" },

    @{ Name = "area:app"; Color = "0052cc"; Description = "Application scope" },
    @{ Name = "area:deploy"; Color = "006b75"; Description = "Deployment manifests and GitOps" },
    @{ Name = "area:infra"; Color = "2b7489"; Description = "Infrastructure and provisioning" },
    @{ Name = "area:hub"; Color = "5319e7"; Description = "Documentation and standards" },
    @{ Name = "area:security"; Color = "b60205"; Description = "Security and compliance" },
    @{ Name = "area:ci-cd"; Color = "1d76db"; Description = "CI/CD pipelines" },
    @{ Name = "area:gitops"; Color = "0e8a16"; Description = "GitOps and ArgoCD" },
    @{ Name = "area:observability"; Color = "fbca04"; Description = "Monitoring, logs, and tracing" }
)

$milestones = @(
    "P00 Foundation",
    "P01 Local Environment",
    "P02 Local Cluster",
    "P03 Containerized App",
    "P04 K8s Artifacts",
    "P05 GitOps",
    "P06 CI Platform",
    "P07 AWS Environment",
    "P08 Ansible",
    "P09 Terraform",
    "P10 Hybrid Orchestration",
    "P11 DevSecOps",
    "P12 Observability and DR",
    "P13 Governance Excellence"
)

Assert-GhCli

if ($DryRun) {
    Write-Host "Dry-run mode enabled. No changes will be applied." -ForegroundColor Yellow
}

foreach ($repository in $Repositories) {
    $fullRepo = "$Owner/$repository"
    Write-Host "Configuring governance for $fullRepo..." -ForegroundColor Cyan

    foreach ($label in $labels) {
        Set-Label -Repo $fullRepo -Name $label.Name -Color $label.Color -Description $label.Description
    }

    foreach ($milestone in $milestones) {
        Set-Milestone -Repo $fullRepo -Title $milestone
    }

    Write-Host "Completed: $fullRepo" -ForegroundColor Green
}

Write-Host "Backlog governance setup finished for all repositories." -ForegroundColor Green
