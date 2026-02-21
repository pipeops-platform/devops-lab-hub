# Branching, Promotion, and CI Governance Policy

## Objective

Define a professional governance standard for branch strategy, environment promotion, pull request controls, and reusable CI workflows across all DevOps Lab repositories.

## Scope

This policy applies to:

- `devops-lab-hub`
- `devops-lab-app`
- `devops-lab-deploy`
- `devops-lab-infra`

## Operating Model

- Development model: trunk-based development with short-lived branches.
- Deployment model: GitOps promotion using environment overlays in the deploy repository.
- Governance model: protected `main` branch + required checks + CODEOWNERS reviews.

## Branch Strategy

### Protected Branch

- `main` is the only long-lived branch.
- Direct push to `main` is blocked.
- All changes must go through pull requests.

### Environment Branches (Prohibited)

- Do not create long-lived branches per environment (`dev`, `staging`, `prod`).
- Environment state must be represented in the deploy repository manifests, not in app repository branches.
- Version traceability per environment must come from deploy PR history + GitOps application status.

### Working Branches

Use short-lived branches with naming convention:

- `feature/<short-description>`
- `fix/<short-description>`
- `hotfix/<short-description>`
- `chore/<short-description>`
- `docs/<short-description>`

## Environment Strategy

Environments are represented by deployment overlays/manifests, not by long-lived Git branches.

- `dev`
- `staging`
- `prod-blue`
- `prod-green`

Promotion happens by pull request that updates environment-specific deployment references.

### Environment Version Traceability

- The deploy repository is the source of truth for "which version is running where".
- Each environment tracks immutable container tags in manifests.
- Promotion events must be auditable through pull requests in the deploy repository.
- ArgoCD application status must be used as runtime evidence of reconciled target version.

## Pull Request Governance

### Required Controls

- Pull request required for merge to `main`.
- No force push on protected branch.
- No branch deletion policy exceptions for protected branch.
- Required conversation resolution before merge.
- Required up-to-date branch before merge.

### Review Policy

- Standard changes: minimum 1 approval.
- Production-impacting changes: minimum 2 approvals.
- CODEOWNERS review required for owned paths.

### Merge Policy

- Prefer squash merge for clean history.
- Commit message must be meaningful and traceable.
- Reverts are allowed as first-line rollback mechanism.

## Required Status Checks

The following checks must be required in branch protection/rulesets:

### app

- Lint
- Unit tests
- Build
- Security scan (dependencies/image)

### deploy

- Manifest validation
- Policy checks
- GitOps compatibility checks

### infra

- Terraform format/validate/plan
- Ansible lint/syntax checks
- IaC security scan

### hub

- Link validation (if enabled)
- Markdown/doc checks (if enabled)

## Reusable Workflow Standard

Reusable workflows must be centrally managed and versioned.

### Mandatory Principles

- Consume reusable workflows via `workflow_call`.
- Reference pinned version tags (for example, `v1`, `v1.1`), never floating branch refs for production.
- Keep workflow interfaces stable and documented.
- Use semantic versioning for workflow releases.

### Minimum Reusable Workflow Catalog

- `reusable-pr-checks`
- `reusable-build-and-publish-image`
- `reusable-security-scan`
- `reusable-update-deploy-repo`
- `reusable-terraform-plan`
- `reusable-terraform-apply`

## Promotion Policy

- `dev`: automatic after merge to `main` where applicable.
- `staging`: promoted by PR with explicit validation.
- `prod-blue` / `prod-green`: promoted by PR with stricter approvals and all checks green.
- Live production exposure is controlled by blue/green cutover, not by changing app branches.

## Release and Rollback

- Image tags must be immutable.
- Release references must include version + commit traceability.
- Rollback strategy is Git-based revert in deploy definitions (GitOps reconciliation handles rollout).

## Security and Secrets

- No hardcoded credentials.
- Environment secrets stored in repository/environment secret stores.
- Cloud authentication in pipelines must prefer OIDC over long-lived keys.

## Implementation Roadmap

### Immediate (Phase 0)

- Approve and publish this policy.
- Apply branch protection baseline in all repositories.
- Enforce CODEOWNERS reviews.

### CI Platform (Phase 6)

- Implement reusable workflow catalog.
- Migrate repositories to centralized reusable workflows.
- Enforce required checks from reusable workflows.

### Cloud Expansion (Phase 7+)

- Apply same promotion and protection policy to cloud-targeted delivery.
- Add environment approvals and deployment gates for higher environments.

## Compliance Checklist

- `main` protected in all repositories.
- Required checks configured and enforced.
- CODEOWNERS active and reviewed.
- PR approval thresholds configured.
- Reusable workflows versioned and consumed by reference.
- Promotion flow (`dev -> staging -> prod-blue/prod-green`) implemented through PRs.
- No long-lived environment branches in application repositories.

## Definition of Done (DoD)

Governance is considered complete when all repositories enforce this policy and every production-relevant change is auditable, reviewed, and validated by required automated checks.
