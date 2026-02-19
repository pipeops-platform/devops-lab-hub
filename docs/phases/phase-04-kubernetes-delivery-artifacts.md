# Phase 4 — Kubernetes Delivery Artifacts

## Objective

Define standardized Kubernetes manifests for repeatable deployment across environments.

## Reference Repository

- `devops-lab-deploy`

## Scope

- Base manifests for Deployment, Service, Ingress
- Environment overlays (dev/staging/prod)
- Validation via manual apply on local k3d cluster

## Steps

1. Create artifact structure in deploy repository.

```text
apps/devops-lab-app/base
apps/devops-lab-app/overlays/dev
apps/devops-lab-app/overlays/staging
apps/devops-lab-app/overlays/prod
```

2. Create base manifests (`Deployment`, `Service`, `Ingress`, `kustomization`).
	- Define probes (`/health`), resources, and image reference.

3. Create overlays for each environment.
	- `dev`: lower footprint, host `devops-lab-app-dev.localtest.me`
	- `staging`: medium footprint, host `devops-lab-app-staging.localtest.me`
	- `prod`: higher footprint, host `devops-lab-app-prod.localtest.me`

4. Import application image into local k3d cluster.

```powershell
k3d image import pipeops/devops-lab-app:0.2.0 -c devops-lab-local
```

5. Apply `dev` overlay and validate rollout.

```powershell
kubectl apply -k apps/devops-lab-app/overlays/dev
kubectl -n devops-lab-app-dev rollout status deploy/devops-lab-app
kubectl -n devops-lab-app-dev get deploy,po,svc,ingress
```

6. Validate ingress routing.

```powershell
curl.exe -s -H "Host: devops-lab-app-dev.localtest.me" http://127.0.0.1/health
```

7. Repeat for `staging` and `prod` when promotion is required.

## Deliverables

- Versioned deployment manifests in deploy repository
- Environment overlays for promotion flow
- Manual validation evidence in local cluster

## Definition of Done (DoD)

Application can be deployed using manifests only, with environment-specific config and stable rollout behavior.
