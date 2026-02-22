# Phase 7 — AWS Cloud Environment

## Objective

Provision and configure AWS runtime environment for the cloud side of the hybrid architecture.

## Execution Mode (Interview Fast-Track)

Given tight timelines, prioritize a **working and auditable baseline** over production-hardening depth.

- Preferred runtime for speed: **k3s on EC2**
- Goal: healthy cluster + secure access + ArgoCD installed + ready for GitOps
- Keep evidence (commands/screenshots) for demo narrative

## Scope

- IAM and access baseline
- Networking baseline
- Kubernetes target environment

## Recommended Target (for this lab)

- **Phase 7**: single AWS cluster (k3s on EC2) with ArgoCD installed
- **Phase 10**: expand to hybrid orchestration (local + AWS)

This keeps Step 7 focused on cloud readiness and avoids overloading with full platform refactoring now.

## Steps

1. Configure AWS account and IAM roles/policies.
2. Create networking baseline (VPC, subnets, security groups).
3. Provision Kubernetes runtime target (k3s on EC2 or EKS).
4. Configure secure admin access and kubeconfig.
5. Install ArgoCD on AWS cluster.
6. Validate cluster health and access.

## Practical Step-by-Step (k3s on EC2)

1. **AWS access baseline**
	- Configure `aws configure` profile for the lab account.
	- Validate identity: `aws sts get-caller-identity`.
2. **Network baseline**
	- Create VPC + 2 subnets + IGW + route table.
	- Security Group minimum rules:
	  - SSH `22/tcp` from your public IP only
	  - HTTP `80/tcp` and HTTPS `443/tcp` for demo access
3. **EC2 provisioning**
	- Launch Ubuntu instance (`t3.large` recommended for stability in demo).
	- Attach key pair and security group.
4. **k3s install**
	- SSH into instance and install k3s server.
	- Confirm node readiness from instance and from your local machine via kubeconfig.
5. **ArgoCD install (AWS cluster)**
	- Create namespace `argocd`.
	- Apply ArgoCD install manifest.
	- Expose access by ingress or temporary port-forward.
6. **Validation evidence**
	- `kubectl get nodes`
	- `kubectl -n argocd get pods`
	- Argo UI reachable

## ArgoCD Topology Decision

Two valid approaches:

1. **One Argo per cluster** (local Argo for local, AWS Argo for AWS)
	- Simpler operationally
	- Better failure isolation
2. **Single control-plane Argo managing multiple clusters**
	- Strong central governance story
	- Slightly more setup complexity

### Recommendation for current timeline

- For Step 7 now: **install a dedicated Argo on AWS** to move fast and reduce risk.
- For Step 10 narrative: present evolution path to **single-pane multi-cluster governance** (if desired).

## Deliverables

- Operational Kubernetes cluster on AWS
- Secure cloud access model
- ArgoCD running on AWS and reachable

## Definition of Done (DoD)

Cloud cluster is healthy, reachable, and ready to receive GitOps-managed deployments.

## Evidence Checklist (for demo)

- AWS instance details (region, instance id, security baseline)
- `kubectl get nodes` showing `Ready`
- `kubectl -n argocd get pods` showing healthy control plane
- Argo UI access proof
- Short explanation of GitOps promotion path to this cluster (implemented next in hybrid phase)
