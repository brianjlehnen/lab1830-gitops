# homelab-gitops

Modern GitOps repository for Lab1830 homelab infrastructure using ArgoCD, Helm, and app-of-apps patterns.

## Repository Structure

```
homelab-gitops/
├── argocd/
│   ├── bootstrap/              # Root ArgoCD applications
│   │   ├── staging.yaml        # Bootstrap app for staging environment
│   │   └── production.yaml     # Bootstrap app for production environment
│   └── apps/
│       ├── staging/            # Staging application definitions
│       └── production/         # Production application definitions
└── charts/                     # Custom Helm charts library
    ├── infrastructure/         # Infrastructure charts
    │   ├── metallb/
    │   ├── nginx-ingress/
    │   └── cert-manager/
    └── applications/           # Application charts
        ├── homepage/
        ├── monitoring/
        └── vault/
```

## Environments

- **Staging**: `staging` branch - For testing and development
- **Production**: `main` branch - Stable production releases

## GitOps Workflow

1. **Development**: Create feature branch from `staging`
2. **Testing**: Merge to `staging` branch → Auto-deploy to staging cluster
3. **Production**: Merge `staging` to `main` → Deploy to production cluster

## Usage

### Deploy to Staging
```bash
git checkout staging
# Make changes
git commit -m "Update application"
git push origin staging
# ArgoCD automatically syncs staging environment
```

### Promote to Production
```bash
git checkout main
git merge staging
git push origin main
# ArgoCD automatically syncs production environment
```

## Applications

### Infrastructure
- MetalLB: LoadBalancer implementation
- NGINX Ingress: Traffic routing and TLS termination
- cert-manager: Automated certificate management

### Applications
- Homepage: Dashboard and service catalog
- Monitoring: Prometheus, Grafana, AlertManager stack
- Various homelab applications and services

## Repository Conventions

- **Helm charts**: All applications use Helm for templating
- **Environment-specific values**: Managed via separate values files
- **GitOps principles**: Declarative, versioned, and automatically deployed
- **App-of-apps pattern**: Hierarchical application management
