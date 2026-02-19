# Phase 6 — CI Platform with GitHub Actions

## Objective

Build a reusable CI platform that automates build, test, scan, publish, and deployment metadata updates.

## Scope

- Standard CI workflow for application repositories
- Reusable workflows and composite actions
- Pipeline bootstrap automation for new repositories

## Steps

1. Create base CI workflow (lint, test, build).
2. Add container image build and publish steps.
3. Add dependency and image security scans.
4. Update deploy repository with new image tag/version.
5. Extract shared logic into reusable workflows (`workflow_call`).
6. Create composite actions for repeated steps.
7. Create bootstrap template to generate pipelines for new repositories.
8. Define versioning strategy for workflow reuse (tags/releases).

## Deliverables

- Reusable workflow catalog
- Standardized pipeline behavior across repositories
- Automated pipeline bootstrap for future services

## Definition of Done (DoD)

New repositories can onboard a compliant CI pipeline by reusing templates/workflows with minimal custom code.
