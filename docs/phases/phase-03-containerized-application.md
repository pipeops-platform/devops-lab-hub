# Phase 3 — Containerized Application

## Objective

Build a containerized application artifact that is portable across local and cloud clusters.

## Scope

- Application scaffold
- Docker image build and local validation
- Image publishing workflow prerequisites

## Steps

1. Create a minimal web application.
2. Add `Dockerfile` and `.dockerignore`.
3. Add unit tests and lint command.
4. Build image locally.
5. Run container and validate health endpoint.
6. Tag image with semantic version and commit SHA.

## Deliverables

- Buildable app source code
- Versioned Docker image
- Basic quality checks (tests/lint)

## Definition of Done (DoD)

Application runs in a container locally, tests pass, and image tags are ready for CI publishing.
