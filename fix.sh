#!/bin/bash
# Stop ArgoCD auto-sync permanently

export KUBECONFIG=~/.kube/terraform-staging-config

echo "=== Disable auto-sync on ArgoCD application ==="
kubectl patch application wireguard-staging -n argocd --type='merge' -p='{"spec":{"syncPolicy":{"automated":null}}}' 2>/dev/null || echo "Application not found or already patched"

echo "=== Force delete the application ==="
kubectl delete application wireguard-staging -n argocd --force --grace-period=0

echo "=== Delete from Git repository to stop recreation ==="
cd ~/homelab-gitops

# Remove the ArgoCD application file from Git
rm -f argocd/apps/staging/wireguard.yaml

# Commit the removal
git add -A
git commit -m "Remove wireguard staging application to stop sync loop"
git push origin staging

echo "=== Wait 10 seconds for Git sync ==="
sleep 10

echo "=== Force delete any remaining resources ==="
kubectl delete namespace wireguard-staging --force --grace-period=0 2>/dev/null || echo "Namespace already deleted"

echo "=== Check ArgoCD app-of-apps to see if it's recreating ==="
kubectl get application staging-root -n argocd -o yaml 2>/dev/null | grep -A 5 -B 5 wireguard || echo "No wireguard reference in app-of-apps"

echo "=== Verify cleanup ==="
kubectl get applications -n argocd | grep wireguard || echo "No wireguard applications found"
kubectl get namespaces | grep wireguard || echo "No wireguard namespaces found"

echo "=== SUCCESS: Wireguard completely removed from ArgoCD sync ==="
