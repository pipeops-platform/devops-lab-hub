# Phase 2 — Local Kubernetes Cluster (k3d)

## Objective

Create a local Kubernetes cluster to simulate the on-prem environment.

## Prerequisites

- Phase 1 complete
- Docker Desktop running

## Steps

1. Create cluster:

```powershell
k3d cluster create devops-lab-local --agents 2
```

2. Validate cluster and context:

```powershell
kubectl config get-contexts
kubectl cluster-info
kubectl get nodes -o wide
```

3. Install ingress controller (nginx):

```powershell
kubectl create namespace ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx
```

4. Deploy a smoke-test app and service.
5. Expose app via ingress and validate local access.

## Deliverables

- Running local k3d cluster
- Ingress controller installed
- Test workload reachable

## Definition of Done (DoD)

Cluster is healthy, ingress works, and test application is accessible through ingress route.
