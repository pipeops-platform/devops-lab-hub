# Phase 9 — Infrastructure as Code with Terraform

## Objective

Provision cloud resources with a versioned, auditable, and repeatable Terraform workflow.

## Scope

- Terraform module structure
- Remote state and locking
- CI integration for plan/apply

## Steps

1. Design Terraform module layout.
2. Implement resources for network, compute, and supporting services.
3. Configure remote state backend and lock mechanism.
4. Add `terraform fmt`, `validate`, and `plan` in CI.
5. Add controlled `apply` strategy with approvals.
6. Validate destroy/recreate reproducibility in non-production scope.

## Deliverables

- Reusable Terraform modules
- Auditable infrastructure pipeline

## Definition of Done (DoD)

Infrastructure can be provisioned and reproduced from code with tracked changes and controlled approvals.
