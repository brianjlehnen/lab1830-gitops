# Lab1830 GitOps Repository

Production homelab infrastructure managed through GitOps workflows using ArgoCD, Helm, and Kubernetes.

## Overview

This repository contains the complete GitOps configuration for a hybrid Kubernetes homelab running production-grade infrastructure services. All deployments are managed declaratively through Git with ArgoCD handling synchronization.

## Technology Stack

**Platform**
- Kubernetes (k3s) - 3-node production cluster
- ArgoCD - GitOps continuous delivery
- Helm - Package management

**Infrastructure**
- HashiCorp Vault - Secrets management (HA cluster)
- cert-manager - Automated TLS certificates
- MetalLB - Bare-metal load balancer
- NGINX Ingress - Traffic routing

**Observability**
- Prometheus - Metrics collection
- Grafana - Visualization and dashboards
- Loki - Log aggregation
- Promtail - Log shipping

**Backup and Storage**
- Velero - Cluster backup and restore
- Restic - File-level backups
- NFS CSI Driver - Dynamic storage provisioning

**Security**
- Network Policies - Pod-to-pod isolation
- Pod Security Standards - Baseline enforcement
- RBAC - Role-based access control
- Wiz - Runtime security monitoring

## Repository Structure

```
.
├── argocd/
│   ├── apps/
│   │   ├── production/      # Production application definitions
│   │   └── staging/         # Staging application definitions
│   └── bootstrap/
│       ├── production.yaml  # Production app-of-apps
│       └── staging.yaml     # Staging app-of-apps
├── charts/
│   ├── applications/        # Application Helm charts
│   │   ├── cert-manager/
│   │   ├── descheduler/
│   │   ├── goldilocks/
│   │   ├── homepage/
│   │   ├── loki/
│   │   ├── monitoring/
│   │   ├── promtail/
│   │   ├── restic/
│   │   ├── velero/
│   │   └── wiz-connector/
│   └── infrastructure/      # Infrastructure Helm charts
│       ├── loki-external/
│       ├── namespace-labels/
│       ├── network-security/
│       ├── pod-security/
│       ├── rbac-security/
│       └── storage/
└── scripts/
    └── vault-staging-setup.sh
```

## Architecture

### GitOps Workflow

```
Git Push → ArgoCD Detects Change → Helm Template → Kubernetes Apply
                ↓
        Manual Sync (Production)
        Auto Sync (Staging)
```

### Multi-Environment Strategy

| Environment | Branch | Sync Policy | Purpose |
|-------------|--------|-------------|---------|
| Production | `main` | Manual | Stable infrastructure services |
| Staging | `staging` | Automated | Testing and validation |

### App-of-Apps Pattern

Bootstrap applications deploy environment-specific workloads:

```yaml
# argocd/bootstrap/production.yaml
# Deploys all apps defined in argocd/apps/production/
```

## Key Design Decisions

**Helm Chart Wrapper Pattern**
- Charts in `charts/applications/` wrap upstream charts as dependencies
- Allows customization while maintaining upgrade path
- Environment-specific values via ArgoCD application specs

**Inline Value Overrides**
- ArgoCD applications contain environment-specific values inline
- No separate values files per environment
- Cleaner repository structure

**Infrastructure as Applications**
- Network policies, RBAC, and security configs deployed as Helm charts
- Versioned and auditable security posture
- Consistent deployment pattern for all resources

## Deployment

### Prerequisites

- Kubernetes cluster (k3s)
- ArgoCD installed
- kubectl configured

### Bootstrap

```bash
# Production environment
kubectl apply -f argocd/bootstrap/production.yaml

# Staging environment
kubectl apply -f argocd/bootstrap/staging.yaml
```

### Adding Applications

1. Create Helm chart in `charts/applications/<app-name>/`
2. Add ArgoCD application in `argocd/apps/<environment>/<app-name>.yaml`
3. Commit and push
4. Sync via ArgoCD (automatic for staging, manual for production)

## Configuration Patterns

### Resource Management

All applications define resource requests and limits:

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"
```

### Storage Classes

| Class | Provider | Use Case |
|-------|----------|----------|
| `local-path` | k3s default | High-performance local storage |
| `nfs-client` | Synology NAS | Shared persistent storage |
| `nfs-logs` | Synology NAS | Log aggregation storage |

### Ingress

All services use NGINX ingress with environment-specific domains:
- Production: `<service>.lab1830.com`
- Staging: `<service>-staging.lab1830.com`

## Security

- **Secrets**: HashiCorp Vault with Kubernetes auth
- **Network**: Default-deny policies with explicit allow rules
- **Pods**: Baseline pod security standards enforced
- **RBAC**: Least-privilege service accounts

## Related Repositories

- [lab1830-infrastructure](https://github.com/brianjlehnen/lab1830-infrastructure) - Terraform and Ansible automation

## License

MIT License - See [LICENSE](LICENSE) for details.
