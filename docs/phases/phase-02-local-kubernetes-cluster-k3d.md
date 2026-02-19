# Phase 2 — Local Kubernetes Cluster (k3d)

## Objective

Create and validate a local Kubernetes cluster to simulate the on-prem environment.

## Prerequisites

- Phase 1 complete
- Docker Desktop running
- `k3d`, `kubectl`, and `helm` installed and available in `PATH`

## Standard Cluster Name

Use this name consistently in all local commands:

```powershell
$CLUSTER_NAME = "devops-lab-local"
```

## Step 1 — Create Local Cluster

Use this command to create the cluster with 1 server, 2 agents, and ingress ports mapped locally.
Traefik is disabled to avoid conflict with `ingress-nginx`.

```powershell
k3d cluster create devops-lab-local `
	--agents 2 `
	--port "80:80@loadbalancer" `
	--port "443:443@loadbalancer" `
	--k3s-arg "--disable=traefik@server:0"
```

## Step 2 — Validate Cluster and Context

```powershell
k3d cluster list
kubectl config get-contexts
kubectl cluster-info
kubectl get nodes -o wide
```

Expected result:
- Context `k3d-devops-lab-local` is current
- All nodes in `Ready` status

## Step 3 — Install Ingress Controller (nginx)

```powershell
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --wait --timeout 10m
kubectl -n ingress-nginx get pods
kubectl -n ingress-nginx get svc
```

## Step 4 — Deploy Smoke Test Workload

Apply a minimal app + service + ingress:

```powershell
@'
apiVersion: v1
kind: Namespace
metadata:
	name: smoke-test
---
apiVersion: apps/v1
kind: Deployment
metadata:
	name: echo
	namespace: smoke-test
spec:
	replicas: 1
	selector:
		matchLabels:
			app: echo
	template:
		metadata:
			labels:
				app: echo
		spec:
			containers:
			- name: echo
				image: hashicorp/http-echo:1.0.0
				args:
				- "-text=devops-lab-phase2-ok"
				ports:
				- containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
	name: echo
	namespace: smoke-test
spec:
	selector:
		app: echo
	ports:
	- port: 80
		targetPort: 5678
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
	name: echo
	namespace: smoke-test
spec:
	ingressClassName: nginx
	rules:
	- host: echo.localtest.me
		http:
			paths:
			- path: /
				pathType: Prefix
				backend:
					service:
						name: echo
						port:
							number: 80
'@ | kubectl apply -f -

kubectl -n smoke-test rollout status deploy/echo --timeout=180s
kubectl -n smoke-test get all,ingress
```

## Step 5 — Validate Local Access Through Ingress

```powershell
curl.exe -s -H "Host: echo.localtest.me" http://127.0.0.1/
```

Expected response:

```text
devops-lab-phase2-ok
```

## Recreate Cluster (Clean Reset)

Use this flow whenever you need to rebuild Phase 2 from scratch.

```powershell
k3d cluster delete devops-lab-local

k3d cluster create devops-lab-local `
	--agents 2 `
	--port "80:80@loadbalancer" `
	--port "443:443@loadbalancer" `
	--k3s-arg "--disable=traefik@server:0"
```

After recreate, rerun:
- Step 2 (validation)
- Step 3 (ingress install)
- Step 4 (smoke workload)
- Step 5 (access validation)

## Optional Cleanup (Keep Cluster, Remove Smoke Test)

```powershell
kubectl delete namespace smoke-test
```

## Deliverables

- Running local k3d cluster
- `ingress-nginx` installed and healthy
- Smoke workload reachable through ingress

## Definition of Done (DoD)

Cluster is healthy, ingress works, and test application is accessible through ingress route.
