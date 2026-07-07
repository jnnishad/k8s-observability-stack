#!/usr/bin/env bash
# Bootstraps the full observability stack (Prometheus, Mimir, Loki, Alloy,
# Grafana) into the "monitoring" namespace of the current kubectl context.
#
# Usage: ./scripts/bootstrap.sh
set -euo pipefail

NAMESPACE="monitoring"

echo "==> Adding Helm repos"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null
helm repo add grafana https://grafana.github.io/helm-charts >/dev/null
helm repo update >/dev/null

echo "==> Ensuring namespace ${NAMESPACE} exists"
kubectl get ns "${NAMESPACE}" >/dev/null 2>&1 || kubectl create ns "${NAMESPACE}"

echo "==> Installing kube-prometheus-stack (Prometheus + Alertmanager)"
helm upgrade --install kube-prom prometheus-community/kube-prometheus-stack \
  -f helm/values-prometheus.yaml -n "${NAMESPACE}" --wait

echo "==> Installing Mimir"
helm upgrade --install mimir grafana/mimir-distributed \
  -f helm/values-mimir.yaml -n "${NAMESPACE}" --wait

echo "==> Installing Loki"
helm upgrade --install loki grafana/loki \
  -f helm/values-loki.yaml -n "${NAMESPACE}" --wait

echo "==> Installing Alloy"
helm upgrade --install alloy grafana/alloy \
  -f helm/values-alloy.yaml -n "${NAMESPACE}" --wait

echo "==> Installing Grafana"
helm upgrade --install grafana grafana/grafana \
  -f helm/values-grafana.yaml -n "${NAMESPACE}" --wait

echo "==> Applying alerting rules"
kubectl apply -f alerts/prometheus-rules.yaml

echo "==> Done. Get the Grafana admin password with:"
echo "    kubectl get secret --namespace ${NAMESPACE} grafana -o jsonpath='{.data.admin-password}' | base64 -d"
