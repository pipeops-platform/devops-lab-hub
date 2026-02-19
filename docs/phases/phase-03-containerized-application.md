# Phase 3 — Containerized Application

## Objective

Build a containerized application artifact that is portable across local and cloud clusters.

## Reference Repository

- `devops-lab-app`

## Scope

- Minimal web application scaffold
- Docker image build and local validation
- Quality checks (lint + unit tests)
- Image tagging strategy for CI publishing

## Steps

1. Create minimal application with health endpoint.

```powershell
# src/main.py
# GET /health -> {"status":"ok"}
```

2. Add dependencies and quality tooling.

```powershell
# requirements.txt (runtime)
# requirements-dev.txt (pytest, ruff, httpx)
```

3. Add `Dockerfile` and `.dockerignore`.

4. Run quality checks locally.

```powershell
pip install -r requirements-dev.txt
ruff check .
pytest -q
```

5. Build image locally.

```powershell
docker build -t pipeops/devops-lab-app:0.1.0 .
```

6. Run container and validate health endpoint.

```powershell
docker run --rm -p 8080:8080 pipeops/devops-lab-app:0.1.0
curl http://127.0.0.1:8080/health
```

Expected response:

```text
{"status":"ok"}
```

7. Tag image for release traceability.

```powershell
# semantic version
docker tag pipeops/devops-lab-app:0.1.0 pipeops/devops-lab-app:0.1.0

# commit SHA tag (example)
docker tag pipeops/devops-lab-app:0.1.0 pipeops/devops-lab-app:sha-<shortsha>
```

## Deliverables

- Buildable app source code with `/health`
- Docker image validated locally
- Image tag strategy (`semver` + `sha`)
- Basic quality checks (`ruff`, `pytest`)

## Definition of Done (DoD)

Application runs in a container locally, health endpoint responds, tests/lint pass, and image tags are ready for CI publishing.
