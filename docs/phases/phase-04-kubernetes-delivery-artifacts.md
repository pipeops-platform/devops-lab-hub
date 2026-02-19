# Phase 4 — Kubernetes Delivery Artifacts

## Objective

Define standardized Kubernetes manifests for repeatable deployment across environments.

## Scope

- Base manifests for Deployment, Service, Ingress
- Environment overlays (dev/staging/prod)
- Validation via manual apply

## Steps

1. Create base manifests for app runtime resources.
2. Define resource requests/limits and readiness/liveness probes.
3. Add environment-specific overlays (e.g., Kustomize or Helm values).
4. Apply manifests manually to local cluster for validation.
5. Verify rollout, service discovery, and ingress routing.

## Deliverables

- Versioned deployment manifests in deploy repository
- Environment overlays for promotion flow

## Definition of Done (DoD)

Application can be deployed using manifests only, with environment-specific config and stable rollout behavior.
