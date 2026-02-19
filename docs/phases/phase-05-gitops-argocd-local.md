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
4. Create ArgoCD applications for target environments (`dev`, `staging`, `prod`).
5. Enable auto-sync and self-heal strategy where appropriate.
6. Test drift detection and rollback scenario.

## Step Mapping (Macro -> Execution)

- `5.4 Create ArgoCD Applications per environment` is the step that covers creating additional environments in ArgoCD.
- Current state can start with `dev` first, then add `staging` and `prod` as separate ArgoCD Applications.

### Reference Commands (Step 5.4)

```bash
# dev
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
	name: devops-lab-app-dev
	namespace: argocd
spec:
	project: default
	source:
		repoURL: https://github.com/pipeops-platform/devops-lab-deploy.git
		targetRevision: main
		path: apps/devops-lab-app/overlays/dev
	destination:
		server: https://kubernetes.default.svc
		namespace: devops-lab-app-dev
	syncPolicy:
		automated:
			prune: true
			selfHeal: true
EOF

# staging
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
	name: devops-lab-app-staging
	namespace: argocd
spec:
	project: default
	source:
		repoURL: https://github.com/pipeops-platform/devops-lab-deploy.git
		targetRevision: main
		path: apps/devops-lab-app/overlays/staging
	destination:
		server: https://kubernetes.default.svc
		namespace: devops-lab-app-staging
	syncPolicy:
		automated:
			prune: true
			selfHeal: true
EOF

# prod
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
	name: devops-lab-app-prod
	namespace: argocd
spec:
	project: default
	source:
		repoURL: https://github.com/pipeops-platform/devops-lab-deploy.git
		targetRevision: main
		path: apps/devops-lab-app/overlays/prod
	destination:
		server: https://kubernetes.default.svc
		namespace: devops-lab-app-prod
	syncPolicy:
		automated:
			prune: true
			selfHeal: true
EOF

kubectl -n argocd get applications
```

## Validation Procedure (Step 5.5)

Use one environment (for example `staging`) to validate drift detection and rollback behavior through self-heal.

```bash
# Baseline (expected: Synced/Healthy and replicas from overlay)
kubectl -n argocd get app devops-lab-app-staging -o wide
kubectl -n devops-lab-app-staging get deploy devops-lab-app -o jsonpath='{.spec.replicas}'

# Inject drift (manual runtime change outside Git)
kubectl -n devops-lab-app-staging scale deploy devops-lab-app --replicas=1

# Observe ArgoCD detect OutOfSync and reconcile back to desired state
kubectl -n argocd get app devops-lab-app-staging -w

# Confirm final state (expected: Synced/Healthy and replicas restored)
kubectl -n argocd get app devops-lab-app-staging -o wide
kubectl -n devops-lab-app-staging get deploy devops-lab-app -o wide
curl.exe -s -H "Host: devops-lab-app-staging.localtest.me" http://127.0.0.1/health
```

Expected behavior:

- Application transitions to `OutOfSync` after manual drift.
- ArgoCD applies self-heal and restores manifest-defined state.
- Application returns to `Synced` and `Healthy`.

## Deliverables

- ArgoCD operational in local cluster
- Git-driven automated deployment flow

## Definition of Done (DoD)

A change merged in deploy repository is reconciled automatically by ArgoCD with traceable sync history.
