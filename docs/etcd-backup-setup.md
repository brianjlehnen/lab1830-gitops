# etcd Backup Configuration (k3s)

k3s uses an embedded etcd cluster for state storage. Snapshots are configured at the host level on the control plane node, not through Kubernetes manifests.

## Configure Automatic Snapshots

SSH to the control plane node:

```bash
ssh k8s-control  # 192.168.4.250
```

Edit the k3s config:

```bash
sudo nano /etc/rancher/k3s/config.yaml
```

Add or update the etcd snapshot settings:

```yaml
etcd-snapshot-schedule-cron: "0 */6 * * *"   # Every 6 hours
etcd-snapshot-retention: 10                    # Keep last 10 snapshots
etcd-snapshot-dir: /var/lib/rancher/k3s/server/db/snapshots
```

Restart k3s:

```bash
sudo systemctl restart k3s
```

## Verify Snapshots

```bash
# List snapshots
sudo k3s etcd-snapshot list

# Take a manual snapshot
sudo k3s etcd-snapshot save --name manual-backup

# Snapshots are stored at:
ls /var/lib/rancher/k3s/server/db/snapshots/
```

## Restore from Snapshot

**WARNING**: This is a destructive operation. All cluster state will be replaced.

```bash
# Stop k3s
sudo systemctl stop k3s

# Restore from snapshot
sudo k3s server --cluster-reset --cluster-reset-restore-path=/var/lib/rancher/k3s/server/db/snapshots/<snapshot-name>

# Start k3s
sudo systemctl start k3s

# Rejoin worker nodes (they will need to be restarted)
# On each worker node:
sudo systemctl restart k3s-agent
```

## Monitoring

An `etcd-snapshot-monitor` CronJob runs in `kube-system` and checks snapshot freshness. If the most recent snapshot is older than 24 hours, the job exits with a non-zero status (visible as Failed pod in monitoring).

The companion PrometheusRule fires `EtcdSnapshotStale` if the monitor job fails, routing an alert through AlertManager.
