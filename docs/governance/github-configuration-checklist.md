# GitHub Configuration Checklist (CLI-First)

## Objective

Provide a practical, repeatable checklist to apply governance configuration across all DevOps Lab repositories using command line automation.

## Repositories in Scope

- `flaviopiccolo-boop/devops-lab-hub`
- `flaviopiccolo-boop/devops-lab-app`
- `flaviopiccolo-boop/devops-lab-deploy`
- `flaviopiccolo-boop/devops-lab-infra`

## Prerequisites

- GitHub CLI installed (`gh --version`)
- Authenticated session (`gh auth login`)
- Access with admin permissions on target repositories

---

## 1) Confirm Authentication and Access

```powershell
gh auth status
```

Expected:

- Active authenticated account
- Token with `repo` and admin-capable scopes for repository settings

---

## 2) Baseline Governance Files in Repositories

Confirm each repo has:

- `CODEOWNERS`
- `CONTRIBUTING.md`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/ISSUE_TEMPLATE/*`

Validation command example:

```powershell
gh api repos/flaviopiccolo-boop/devops-lab-hub/contents/CODEOWNERS
```

---

## 3) Labels and Milestones

Run the automation script from `devops-lab-hub`:

```powershell
cd E:\Github\devops-lab\hub\devops-lab-hub
.\scripts\setup-github-backlog-governance.ps1
```

Dry-run preview:

```powershell
.\scripts\setup-github-backlog-governance.ps1 -DryRun
```

---

## 4) Protect `main` Branch (PR-Only)

Apply branch protection using GitHub API for each repository:

```powershell
gh api -X PUT repos/flaviopiccolo-boop/devops-lab-hub/branches/main/protection \
  --input - <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": []
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_linear_history": true,
  "lock_branch": false,
  "allow_fork_syncing": true
}
JSON
```

Notes:

- Repeat for each repository (`app`, `deploy`, `infra`).
- Keep `contexts` empty until CI checks are finalized, then update required checks.

---

## 5) Configure Required Checks (after CI workflow names are final)

Update branch protection with actual check names from your workflows.

Suggested baseline by repository:

- `app`: lint, test, build, security-scan
- `deploy`: manifest-validate, policy-check
- `infra`: terraform-validate, terraform-plan, ansible-lint
- `hub`: docs-check (optional)

---

## 6) Repository Security and Merge Settings

Recommended settings for each repository:

- Disable merge commits (optional, if using squash-only)
- Enable squash merge
- Enable auto-delete head branches
- Enable vulnerability alerts and Dependabot security updates

Example commands:

```powershell
gh api -X PATCH repos/flaviopiccolo-boop/devops-lab-hub -f allow_squash_merge=true -f allow_merge_commit=false -f delete_branch_on_merge=true
gh api -X PUT repos/flaviopiccolo-boop/devops-lab-hub/vulnerability-alerts
```

---

## 7) Environments and Deployment Gates (staging/prod)

Create environments (especially in deploy/app as needed):

```powershell
gh api -X PUT repos/flaviopiccolo-boop/devops-lab-deploy/environments/dev
gh api -X PUT repos/flaviopiccolo-boop/devops-lab-deploy/environments/staging
gh api -X PUT repos/flaviopiccolo-boop/devops-lab-deploy/environments/prod
```

Then configure environment protection rules (reviewers/wait timer) through API or UI.

---

## 8) Validation Checklist

- `main` protected in all 4 repositories
- PR required, force push blocked
- CODEOWNERS review required
- Labels and milestones standardized
- Security alerts enabled
- Environment objects created (`dev/staging/prod`)
- Required checks configured (after CI finalization)

---

## 9) What is Better in CLI vs UI?

CLI-first (recommended):

- Repeatable setup
- Versionable scripts
- Faster rollout across multiple repositories

UI can still be useful for:

- One-off inspection and quick confirmation
- Fine-grained environment reviewer setup
- Troubleshooting check names and policy visibility

## Definition of Done (DoD)

All governance controls are active in all repositories, validated, and reproducible through documented CLI procedures.
