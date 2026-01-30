# k3s State Backup Configuration

This k3s cluster uses SQLite (the default single-server datastore), not embedded etcd. The cluster state is stored at `/var/lib/rancher/k3s/server/db/state.db` on the control plane node.

## Automatic Backups

A `k3s-backup` CronJob runs in `kube-system` every 6 hours. It:
1. Copies `state.db` to a timestamped backup in `/var/lib/rancher/k3s/server/db/backups/`
2. Prunes backups older than 7 days
3. Verifies the latest backup is fresh (exits non-zero if stale)

The CronJob is deployed via ArgoCD from `charts/infrastructure/etcd-monitor/`.

## Manual Backup

SSH to the control plane node:

```bash
ssh k8s-control  # 192.168.4.250
```

```bash
sudo mkdir -p /var/lib/rancher/k3s/server/db/backups
sudo cp /var/lib/rancher/k3s/server/db/state.db \
  /var/lib/rancher/k3s/server/db/backups/state-$(date +%Y%m%d-%H%M%S).db
```

## Restore from Backup

**WARNING**: This is a destructive operation. All cluster state will be replaced.

```bash
# Stop k3s
sudo systemctl stop k3s

# Replace state.db with backup
sudo cp /var/lib/rancher/k3s/server/db/backups/<backup-file>.db \
  /var/lib/rancher/k3s/server/db/state.db

# Start k3s
sudo systemctl start k3s

# Worker nodes may need restart
# On each worker node:
sudo systemctl restart k3s-agent
```

## Switching to Embedded etcd (Optional)

If you later want HA with multiple control plane nodes, you can migrate to embedded etcd:

```bash
# Stop k3s on all nodes
sudo systemctl stop k3s

# Reinitialize with etcd
sudo k3s server --cluster-init

# Then etcd snapshot commands become available:
sudo k3s etcd-snapshot list
sudo k3s etcd-snapshot save --name manual-backup
```

This requires reconfiguring all worker nodes to rejoin.

## Monitoring

A PrometheusRule fires `K3sBackupStale` if the backup CronJob fails, routing an alert through AlertManager to brian@lab1830.com.
