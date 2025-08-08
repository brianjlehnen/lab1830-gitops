#!/bin/bash
# Quick Vault staging configuration after reset
set -e

echo "Waiting for Vault to be ready..."
kubectl wait --for=condition=ready pod -n vault -l app.kubernetes.io/name=vault --timeout=120s

echo "Configuring Vault authentication..."
kubectl exec -n vault vault-staging-0 -- sh -c 'VAULT_TOKEN=staging-root-token-12345 vault auth enable kubernetes 2>/dev/null || echo "Kubernetes auth already enabled"'

kubectl exec -n vault vault-staging-0 -- sh -c 'VAULT_TOKEN=staging-root-token-12345 vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host="https://kubernetes.default.svc" \
    kubernetes_ca_cert="$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)"'

echo "Creating backup secrets..."
kubectl exec -n vault vault-staging-0 -- sh -c 'VAULT_TOKEN=staging-root-token-12345 vault kv put secret/backup/restic/staging \
    repository="s3:http://minio.backup.svc.cluster.local:9000/restic-staging" \
    password="staging-restic-password-123" \
    aws_access_key="backup-staging" \
    aws_secret_key="backup-staging-secret"'

echo "Creating backup policy..."
kubectl exec -n vault vault-staging-0 -- sh -c 'VAULT_TOKEN=staging-root-token-12345 vault policy write backup-policy - <<EOF
path "secret/data/backup/*" {
  capabilities = ["read"]
}
path "secret/metadata/backup/*" {
  capabilities = ["list"]
}
EOF'

echo "Creating Kubernetes role..."
kubectl exec -n vault vault-staging-0 -- sh -c 'VAULT_TOKEN=staging-root-token-12345 vault write auth/kubernetes/role/backup-service \
    bound_service_account_names=restic-backup,velero \
    bound_service_account_namespaces=backup,velero \
    policies=backup-policy \
    ttl=1h'

echo "Vault staging configuration complete"
echo "Access UI: http://localhost:8200/ui/ (via SSH tunnel)"
echo "Token: staging-root-token-12345"