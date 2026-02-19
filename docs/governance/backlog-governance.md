# Backlog Governance — Labels and Milestones Standard

## Objective

Standardize issue triage and planning across all repositories:

- `devops-lab-hub`
- `devops-lab-app`
- `devops-lab-deploy`
- `devops-lab-infra`

## Label Standard

Use the same label taxonomy in every repository.

### Type Labels

- `bug` — Defect or incorrect behavior
- `enhancement` — New feature or improvement
- `task` — Planned technical activity
- `docs` — Documentation-only work
- `chore` — Maintenance and housekeeping

### Priority Labels

- `priority:low`
- `priority:medium`
- `priority:high`
- `priority:critical`

### Status Labels

- `status:triage`
- `status:ready`
- `status:in-progress`
- `status:blocked`
- `status:review`
- `status:done`

### Area Labels

- `area:app`
- `area:deploy`
- `area:infra`
- `area:hub`
- `area:security`
- `area:ci-cd`
- `area:gitops`
- `area:observability`

## Milestone Convention

Create milestones per macro phase to keep execution traceable.

- `P00 Foundation`
- `P01 Local Environment`
- `P02 Local Cluster`
- `P03 Containerized App`
- `P04 K8s Artifacts`
- `P05 GitOps`
- `P06 CI Platform`
- `P07 AWS Environment`
- `P08 Ansible`
- `P09 Terraform`
- `P10 Hybrid Orchestration`
- `P11 DevSecOps`
- `P12 Observability and DR`
- `P13 Governance Excellence`

## Assignment Rules

1. Every issue must include exactly one type label.
2. Every issue must include one priority label.
3. Every issue must include one area label.
4. Every issue must be assigned to one milestone.
5. Status labels are lifecycle-driven and updated as work progresses.

## Planning Rules

- Keep milestones small and finishable.
- Prefer splitting large issues into small, testable tasks.
- Move blocked issues to `status:blocked` with blocker explanation.
- Close issues only when Definition of Done is met.

## Suggested Initial Rollout

1. Create all labels in each repository.
2. Create milestones `P00` to `P13`.
3. Triage existing issues with the standard.
4. Enforce usage through pull request reviews.

## Automation

You can automate label and milestone provisioning across all repositories using:

- `scripts/setup-github-backlog-governance.ps1`

### Prerequisites

- GitHub CLI installed (`gh`)
- Authenticated session (`gh auth login`)

### Run

From repository root (`devops-lab-hub`):

```powershell
.\scripts\setup-github-backlog-governance.ps1
```

Optional custom owner/repository set:

```powershell
.\scripts\setup-github-backlog-governance.ps1 -Owner "your-org" -Repositories @("repo-a","repo-b")
```

Dry-run preview (no changes applied):

```powershell
.\scripts\setup-github-backlog-governance.ps1 -DryRun
```

## Definition of Done (DoD)

Backlog governance is complete when all repositories use the same label model and all active issues are triaged with type, priority, area, status, and milestone.
