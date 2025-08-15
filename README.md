# Lab1830 GitOps Repository

Homelab infrastructure managed through GitOps workflow using ArgoCD.

## Overview

This repository contains Helm charts and ArgoCD applications for managing a hybrid Kubernetes + Docker homelab infrastructure with production, staging, and edge environments.

## Architecture

- **Platform:** k3s Kubernetes clusters
- **GitOps:** ArgoCD with manual sync policies
- **Secrets:** HashiCorp Vault
- **Environments:** Production, Staging, Edge clusters
 
## Repository Structure
```bash
├── argocd
│   ├── apps
│   │   ├── production
│   │   └── staging
│   └── bootstrap
│       ├── production.yaml
│       └── staging.yaml
├── charts
│   ├── applications
│   │   ├── cert-manager
│   │   ├── descheduler
│   │   ├── homepage
│   │   ├── loki
│   │   ├── monitoring
│   │   ├── promtail
│   │   ├── restic
│   │   ├── vault
│   │   ├── velero
│   │   ├── wireguard
│   │   └── wiz-connector
│   └── infrastructure
│       ├── loki-external
│       └── storage
├── README.md
└── scripts
```
## Key Services

- **Infrastructure:** ArgoCD, Prometheus, Grafana, Loki, Vault, Velero, Restic
- **Applications:** Homepage dashboard, monitoring stack, backup solutions
- **Security:** HashiCorp Vault secrets management, certificate management

## Usage

This repository is designed for ArgoCD consumption. Applications are deployed through GitOps workflow with environment-specific value overrides.

## Technology Stack

- Kubernetes (k3s)
- ArgoCD
- Helm
- HashiCorp Vault
- MetalLB
- NGINX Ingress
- cert-manager
