# Phase 7 — AWS Cloud Environment

## Objective

Provision and configure AWS runtime environment for the cloud side of the hybrid architecture.

## Scope

- IAM and access baseline
- Networking baseline
- Kubernetes target environment

## Steps

1. Configure AWS account and IAM roles/policies.
2. Create networking baseline (VPC, subnets, security groups).
3. Provision Kubernetes runtime target (k3s on EC2 or EKS).
4. Configure secure admin access and kubeconfig.
5. Install ArgoCD on AWS cluster.
6. Validate cluster health and access.

## Deliverables

- Operational Kubernetes cluster on AWS
- Secure cloud access model

## Definition of Done (DoD)

Cloud cluster is healthy, reachable, and ready to receive GitOps-managed deployments.
