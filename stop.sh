#!/bin/bash
# Stop ArgoCD from recreating pods

export KUBECONFIG=~/.kube/terraform-staging-config

echo "=== Check if ArgoCD application still exists ==="
kubectl get applications -n argocd | grep wireguard

echo "=== Force delete any remaining ArgoCD applications ==="
kubectl delete applications -n argocd -l app.kubernetes.io/name=wireguard --force --grace-period=0 2>/dev/null || echo "No ArgoCD apps found"

echo "=== Check for any wireguard deployments ==="
kubectl get deployments -A | grep wireguard

echo "=== Force delete all wireguard deployments ==="
kubectl delete deployment --all -n wireguard-staging --force --grace-period=0 2>/dev/null || echo "No deployments in wireguard-staging"
kubectl delete deployment --all -n wireguard-test --force --grace-period=0 2>/dev/null || echo "No deployments in wireguard-test"

echo "=== Delete all wireguard namespaces ==="
for ns in wireguard-staging wireguard-test wireguard; do
  kubectl delete namespace $ns --force --grace-period=0 2>/dev/null || echo "Namespace $ns not found"
done

echo "=== Wait 5 seconds ==="
sleep 5

echo "=== Verify complete cleanup ==="
kubectl get pods -A | grep wireguard || echo "No wireguard pods found"
kubectl get namespaces | grep wireguard || echo "No wireguard namespaces found"
kubectl get applications -n argocd | grep wireguard || echo "No wireguard ArgoCD apps found"

echo "=== Check ArgoCD logs for sync errors ==="
kubectl logs -n argocd deployment/argocd-application-controller --tail=10 | grep -i wireguard || echo "No wireguard errors in ArgoCD logs"
