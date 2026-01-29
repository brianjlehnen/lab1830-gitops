#!/bin/bash
# Quick Vault staging configuration after reset
# Usage: VAULT_STAGING_TOKEN=<token> ./scripts/vault-staging-setup.sh
set -e

if [ -z "${VAULT_STAGING_TOKEN}" ]; then
  echo "ERROR: VAULT_STAGING_TOKEN environment variable must be set"
  echo "Usage: VAULT_STAGING_TOKEN=<token> $0"
  exit 1
fi

echo "Waiting for Vault to be ready..."
kubectl wait --for=condition=ready pod -n vault -l app.kubernetes.io/name=vault --timeout=120s

echo "Configuring Vault authentication..."
kubectl exec -n vault vault-staging-0 -- sh -c "VAULT_TOKEN=${VAULT_STAGING_TOKEN} vault auth enable kubernetes 2>/dev/null || echo 'Kubernetes auth already enabled'"

kubectl exec -n vault vault-staging-0 -- sh -c "VAULT_TOKEN=${VAULT_STAGING_TOKEN} vault write auth/kubernetes/config \
    token_reviewer_jwt=\"\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)\" \
    kubernetes_host=\"https://kubernetes.default.svc\" \
    kubernetes_ca_cert=\"\$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)\""

echo "Creating backup secrets..."
kubectl exec -n vault vault-staging-0 -- sh -c "VAULT_TOKEN=${VAULT_STAGING_TOKEN} vault kv put secret/backup/restic/staging \
    repository=\"s3:http://minio.backup.svc.cluster.local:9000/restic-staging\" \
    password=\"\$(openssl rand -base64 24)\" \
    aws_access_key=\"backup-staging\" \
    aws_secret_key=\"\$(openssl rand -base64 32)\""

echo "Creating backup policy..."
kubectl exec -n vault vault-staging-0 -- sh -c "VAULT_TOKEN=${VAULT_STAGING_TOKEN} vault policy write backup-policy - <<EOF
path \"secret/data/backup/*\" {
  capabilities = [\"read\"]
}
path \"secret/metadata/backup/*\" {
  capabilities = [\"list\"]
}
EOF"

echo "Creating Kubernetes role..."
kubectl exec -n vault vault-staging-0 -- sh -c "VAULT_TOKEN=${VAULT_STAGING_TOKEN} vault write auth/kubernetes/role/backup-service \
    bound_service_account_names=restic-backup,velero \
    bound_service_account_namespaces=backup,velero \
    policies=backup-policy \
    ttl=1h"

echo "Vault staging configuration complete"
echo "Access UI: http://localhost:8200/ui/ (via SSH tunnel)"
echo "Token: (provided via VAULT_STAGING_TOKEN env var)"
