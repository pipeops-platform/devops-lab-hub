# Phase 8 — Configuration Management with Ansible

## Objective

Automate host and node configuration for reproducible platform setup.

## Scope

- Inventory and role model
- Runtime prerequisites and hardening
- Repeatable host bootstrap

## Steps

1. Define inventory for local and AWS targets.
2. Create reusable Ansible roles for container runtime/dependencies.
3. Automate Kubernetes prerequisites and node configuration.
4. Apply baseline hardening controls.
5. Validate idempotent re-execution.

## Deliverables

- Structured Ansible inventory and roles
- Reproducible host configuration process

## Definition of Done (DoD)

Running playbooks repeatedly produces consistent host state without unintended changes.
