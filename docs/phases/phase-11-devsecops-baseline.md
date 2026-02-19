# Phase 11 — DevSecOps Baseline

## Objective

Embed security controls into the development, delivery, and runtime lifecycle.

## Scope

- Secrets and identity controls
- Runtime segmentation and policy
- Security checks in CI/CD

## Steps

1. Implement secrets management pattern.
2. Enforce RBAC and namespace isolation.
3. Apply Kubernetes NetworkPolicies.
4. Add image scan/signature verification gates.
5. Add IaC and dependency vulnerability scans.
6. Enforce policy checks before deployment.

## Deliverables

- Security gates in pipeline and cluster
- Baseline compliance controls

## Definition of Done (DoD)

Pipeline and runtime enforce security controls with measurable pass/fail gates before production promotion.
