# Lab1830 GitOps Repository

Enterprise-grade homelab infrastructure managed through GitOps workflow using ArgoCD.

## Overview

This repository contains Helm charts and ArgoCD applications for managing a hybrid Kubernetes + Docker homelab infrastructure with production, staging, and edge environments.

## Architecture

- **Platform:** k3s Kubernetes clusters
- **GitOps:** ArgoCD with manual sync policies
- **Secrets:** HashiCorp Vault
- **Environments:** Production, Staging, Edge clusters

## Repository Structure
├── argocd/
│   ├── apps/
│   │   ├── production/     # Production applications
│   │   └── staging/        # Staging applications
│   └── bootstrap/          # Environment initialization
└── charts/
├── applications/       # Custom Helm charts
└── infrastructure/     # Core platform services

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