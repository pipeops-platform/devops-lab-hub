# Phase 5 — GitOps with ArgoCD (Local)

## Objective

Enable GitOps delivery in the local cluster using ArgoCD and deploy repository as source of truth.

## Prerequisites

- Phase 2 cluster available
- Phase 4 manifests ready

## Steps

1. Install ArgoCD in local cluster.
2. Secure admin access and update credentials.
3. Register deploy repository in ArgoCD.
4. Create ArgoCD applications for target environments.
5. Enable auto-sync and self-heal strategy where appropriate.
6. Test drift detection and rollback scenario.

## Deliverables

- ArgoCD operational in local cluster
- Git-driven automated deployment flow

## Definition of Done (DoD)

A change merged in deploy repository is reconciled automatically by ArgoCD with traceable sync history.
