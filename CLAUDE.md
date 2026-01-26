# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a GitOps repository for managing Lab1830 homelab infrastructure using ArgoCD and Helm. All infrastructure and applications are deployed through Git commits following the GitOps pattern.

## Cluster Architecture

### Physical Infrastructure

**Kubernetes Cluster (k3s v1.32.5+k3s1)**
- **k8s-control** (192.168.4.250): Dell OptiPlex 990, 8GB RAM, Ubuntu 25.04
- **k8s-node1** (192.168.4.251): HP EliteDesk 800 G2, 16GB RAM, Ubuntu 25.04
- **k8s-node2** (192.168.4.252): HP EliteDesk 800 G2, 32GB RAM, Ubuntu 25.04

**External Systems**
- **titan** (192.168.4.156): Docker host for media services (Plex, *arr stack)
- **raspberrypi** (192.168.4.254): ARM64 edge cluster - runs AdGuard Home (NOT in main k8s cluster)
- **Synology NAS** (192.168.4.159): Network storage

### Service Distribution

| IP | Purpose | Services |
|----|---------|----------|
| 192.168.4.200 | K8s/MetalLB | ArgoCD, Grafana, Homepage, Vault, Authentik |
| 192.168.4.201 | K8s/MetalLB | AdGuard Home DNS service (queries only) |
| 192.168.4.156 | Docker/Traefik | Plex, Overseerr, Radarr, Sonarr, Prowlarr, SABnzbd |
| 192.168.4.159 | NAS | Synology storage services |
| 192.168.4.254 | Raspberry Pi | AdGuard Home web UI and management |

### Cluster Context Aliases

```bash
kp  # Switch to production cluster
ks  # Switch to staging cluster
```

## Key Commands

### Environment Deployment

```bash
# Deploy changes to staging
git checkout staging
git add .
git commit -m "feat: description of changes"
git push origin staging

# Promote to production
git checkout main
git merge staging
git push origin main
```

### Common Operations

```bash
# Check all pods
kubectl get pods -A

# Check ArgoCD app status
kubectl get applications -n argocd

# Force ArgoCD sync
argocd app sync <app-name>

# Restart deployment after ConfigMap changes
kubectl rollout restart deployment <name> -n <namespace>

# Check certificates
kubectl get certificates -A

# View SOPS encrypted secrets locally
sops --decrypt <secret-file>.yaml
```

### Vault Setup (Staging)

```bash
# Initialize Vault for staging environment
./scripts/vault-staging-setup.sh

# Access: http://localhost:8200/ui/ (SSH tunnel required)
# Token: staging-root-token-12345
```

## Architecture

### Repository Structure

- `argocd/bootstrap/`: Root ArgoCD applications for each environment
- `argocd/apps/`: Environment-specific application definitions
- `charts/applications/`: Custom Helm charts for applications
- `charts/infrastructure/`: Infrastructure component charts
- `scripts/`: Utility scripts for setup and maintenance

### Environment Strategy

- **Staging** (`staging` branch): Auto-deploys on push, uses `*-staging.lab1830.com`
- **Production** (`main` branch): Manual promotion from staging, uses `*.lab1830.com`

### Namespace Conventions

- Staging: `<app>-staging` (e.g., `homepage-staging`, `monitoring-staging`)
- Production: `<app>-production` (e.g., `homepage-production`, `monitoring-production`)

### App-of-Apps Pattern

Bootstrap applications (`argocd/bootstrap/staging.yaml` and `production.yaml`) automatically deploy all child applications defined in `argocd/apps/`. Each environment has its own bootstrap that references environment-specific application definitions.

### Application Configuration Pattern

When adding or modifying applications:
1. Create/update Helm chart in `charts/applications/{app-name}/`
2. Add ArgoCD application definition in `argocd/apps/{environment}/{app-name}.yaml`
3. Use environment-specific value overrides in the ArgoCD application spec

Example ArgoCD application structure:
```yaml
spec:
  source:
    repoURL: git@github.com:brianjlehnen/homelab-gitops.git
    targetRevision: staging  # or main for production
    path: charts/applications/{app-name}
    helm:
      valueFiles: [values.yaml]
      values: |
        # Environment-specific overrides
```

## Certificate Management

### Internal Services (cert-manager)
- Self-signed CA for internal Kubernetes services
- Certificates auto-renew via cert-manager
- ClusterIssuer: `letsencrypt-prod` available for external certs using Cloudflare DNS-01

### Let's Encrypt Certificates

```bash
# Check certificate status
kubectl get certificates -A
kubectl describe certificate <name> -n <namespace>

# Force renewal (delete and let cert-manager recreate)
kubectl delete certificate <name> -n <namespace>

# Check cert-manager logs
kubectl logs -n cert-manager deploy/cert-manager --tail=100
```

### AdGuard Home (Raspberry Pi Edge Cluster)
- **NOT managed by cert-manager** - runs on separate Pi at 192.168.4.254
- Requires manual certificate renewal (~90 days)
- To renew: Generate cert via production cert-manager, extract, upload via AdGuard UI

```bash
# Generate cert for AdGuard using production cluster
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: adguard-edge-tls
  namespace: cert-manager
spec:
  dnsNames:
    - adguard.lab1830.com
  secretName: adguard-edge-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
EOF

# Wait for Ready=True
kubectl get certificate adguard-edge-tls -n cert-manager -w

# Extract cert and key
kubectl get secret adguard-edge-tls -n cert-manager -o jsonpath='{.data.tls\.crt}' | base64 -d > /tmp/adguard.crt
kubectl get secret adguard-edge-tls -n cert-manager -o jsonpath='{.data.tls\.key}' | base64 -d > /tmp/adguard.key

# Upload via AdGuard UI: Settings → Encryption Settings
# Then cleanup:
kubectl delete certificate adguard-edge-tls -n cert-manager
kubectl delete secret adguard-edge-tls -n cert-manager
```

## Secrets Management

### SOPS + Age Encryption
- All secrets encrypted with SOPS + Age before committing
- ArgoCD repo-server has CMP sidecar for automatic decryption
- Age key stored in `sops-age` secret in argocd namespace

```bash
# Encrypt a secret
sops --encrypt --in-place secret.yaml

# Decrypt locally to view
sops --decrypt secret.yaml

# Verify ArgoCD can decrypt
kubectl get secret sops-age -n argocd
```

### Vault (HashiCorp)
- 2-node HA cluster with Raft storage
- Access: https://vault.lab1830.com
- Requires manual unsealing after pod restarts

## Resource Management

- Staging: Conservative resources (25-100m CPU, 64-256Mi memory)
- Production: Production-appropriate limits
- All applications should define resource requests and limits

### Storage Classes
- `local-path`: Local storage for ephemeral data
- `nfs-client`: Shared persistent storage (Synology NAS)
- `nfs-logs`: Log aggregation storage

## Ingress Configuration

All applications use NGINX ingress with environment-specific domains:
- Staging: `{app}-staging.lab1830.com`
- Production: `{app}.lab1830.com`

MetalLB LoadBalancer pool: 192.168.4.200-192.168.4.210

## Monitoring & Logging

- **Grafana**: https://grafana.lab1830.com (kube-prometheus-stack)
- **Prometheus**: Metrics collection (kube-prometheus-stack)
- **Loki**: Log aggregation (Kubernetes-native cluster)
- **Promtail**: Log shipping to Loki

```bash
# Check monitoring stack
kubectl get pods -n monitoring-production

# Port-forward Grafana locally
kubectl port-forward -n monitoring-production svc/monitoring-production-grafana 3000:80
```

## Troubleshooting

### Pod Issues
```bash
kubectl describe pod <name> -n <namespace>
kubectl logs <pod> -n <namespace> --tail=100
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

### ArgoCD Sync Issues
```bash
kubectl get applications -n argocd
kubectl describe application <app> -n argocd
argocd app sync <app> --prune
```

### DNS Issues (AdGuard)
```bash
dig @192.168.4.201 google.com
dig @192.168.4.201 argocd.lab1830.com
```

## Important Notes

- Never commit secrets directly - use SOPS encryption or Vault
- Test all changes in staging before promoting to production
- ArgoCD auto-sync is enabled but prune and self-heal are disabled for safety
- Use ServerSideApply for all ArgoCD applications to handle CRDs properly
- Check application health in ArgoCD UI after deployments
- ConfigMap changes require pod restart: `kubectl rollout restart deployment <name> -n <namespace>`
- Kyverno policies: Staging uses `Enforce`, Production uses `Audit` mode