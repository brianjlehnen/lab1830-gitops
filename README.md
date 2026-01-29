# Lab1830 GitOps Repository

Homelab infrastructure managed through GitOps workflow using ArgoCD.

## Overview

This repository contains Helm charts and ArgoCD applications for managing a hybrid Kubernetes + Docker homelab infrastructure with production, staging, and edge environments.

## Architecture

- **Platform:** k3s Kubernetes clusters (production + staging)
- **GitOps:** ArgoCD with App-of-Apps pattern
- **Secrets:** SOPS + Age encryption, Kubernetes secrets
- **Environments:** Production (`main` branch), Staging (`staging` branch), Edge (Raspberry Pi)

## Repository Structure
```bash
├── argocd
│   ├── apps
│   │   ├── production          # Production ArgoCD Application definitions
│   │   └── staging             # Staging ArgoCD Application definitions
│   └── bootstrap
│       ├── production.yaml     # Production bootstrap (App-of-Apps root)
│       └── staging.yaml        # Staging bootstrap (App-of-Apps root)
├── charts
│   ├── applications
│   │   ├── authentik           # SSO/Identity Provider
│   │   ├── cert-manager        # TLS certificate management
│   │   ├── descheduler         # Pod rescheduling
│   │   ├── goldilocks          # Resource recommendations
│   │   ├── homepage            # Dashboard
│   │   ├── kyverno             # Policy engine
│   │   ├── kyverno-policies    # Custom Kyverno policies
│   │   ├── loki                # Log aggregation
│   │   ├── monitoring          # Prometheus + Grafana stack
│   │   ├── promtail            # Log shipping
│   │   ├── velero              # Cluster backups
│   │   ├── wireguard           # VPN
│   │   └── wiz-connector       # Security scanning
│   └── infrastructure
│       ├── loki-external       # External Loki access (NodePort)
│       ├── namespace-labels    # Namespace label management
│       ├── network-security    # NetworkPolicies
│       ├── pod-security        # PodDisruptionBudgets
│       ├── rbac-security       # ClusterRoles and bindings
│       └── storage             # NFS storage classes
├── scripts
│   └── vault-staging-setup.sh
├── CLAUDE.md                   # Claude Code instructions
└── README.md
```

## Key Services

- **Identity & Access:** Authentik (SSO/OAuth provider)
- **Monitoring:** Prometheus, Grafana, Loki, Promtail, Velero backup alerts
- **Backups:** Velero with MinIO/NAS storage
- **Security:** Kyverno policy engine, network policies, RBAC, cert-manager (Let's Encrypt)
- **Applications:** Homepage dashboard, Goldilocks resource advisor
- **Infrastructure:** ArgoCD, MetalLB, NGINX Ingress, NFS storage

## Usage

This repository is designed for ArgoCD consumption. Changes are deployed via Git:

```bash
# Deploy to staging
git checkout staging && git push origin staging

# Promote to production
git checkout main && git merge staging && git push origin main
```

## Technology Stack

- Kubernetes (k3s)
- ArgoCD
- Helm
- SOPS + Age (secrets encryption)
- MetalLB
- NGINX Ingress
- cert-manager (Let's Encrypt via Cloudflare DNS-01)
- Kyverno
- Authentik
- Prometheus / Grafana / Loki
- Velero
