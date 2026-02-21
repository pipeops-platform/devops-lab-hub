# Phase 10 — Hybrid Deployment Orchestration

## Objective

Run the same application release across local (on-prem simulation) and AWS clusters with controlled promotion.

## Scope

- Environment separation
- Multi-cluster deployment targets
- Promotion flow validation
- Blue/Green production rollout strategy

## Steps

1. Separate manifests/config by environment.
2. Configure ArgoCD targets for local and AWS clusters.
3. Deploy identical application version to both clusters.
4. Validate behavior parity and connectivity.
5. Validate promotion flow (`dev -> staging -> prod`).
6. Implement and validate Blue/Green switch in production scope.

## Blue/Green Automation

Use the operational script to switch the live production host between slots:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\switch-prod-slot.ps1 -Status
powershell -ExecutionPolicy Bypass -File .\scripts\switch-prod-slot.ps1 -Target blue
powershell -ExecutionPolicy Bypass -File .\scripts\switch-prod-slot.ps1 -Target green
```

The script validates target slot health before cutover and confirms live host ownership after switch.

## Deliverables

- Multi-environment deployment strategy
- Hybrid deployment parity validation
- Documented Blue/Green rollout and switch-back procedure

## Definition of Done (DoD)

A single versioned release can be promoted predictably across both cluster types with traceable history, including validated Blue/Green production cutover and rollback.
