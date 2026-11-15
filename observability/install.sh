#!/usr/bin/env bash
set -euo pipefail

: "${GRAFANA_ADMIN_PASSWORD:?Set GRAFANA_ADMIN_PASSWORD before installing the monitoring stack}"

kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
kubectl -n observability create secret generic grafana-admin \
  --from-literal=admin-user=admin \
  --from-literal=admin-password="$GRAFANA_ADMIN_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f observability/hello-api-dashboard.yaml

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add grafana-community https://grafana-community.github.io/helm-charts
helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace observability --values observability/prometheus-values.yaml
helm upgrade --install loki grafana-community/loki \
  --namespace observability --values observability/loki-values.yaml
helm upgrade --install tempo grafana-community/tempo \
  --namespace observability --values observability/tempo-values.yaml
helm upgrade --install alloy grafana/alloy \
  --namespace observability --values observability/alloy-values.yaml

printf '\nMonitoring stack installed. Open Grafana with:\n'
printf 'kubectl -n observability port-forward svc/kube-prometheus-stack-grafana 3000:80\n'
