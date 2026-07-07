# k8s-observability-stack

A production-shaped observability platform for Kubernetes: **Prometheus →
Mimir** for metrics, **Alloy → Loki** for logs, and **Grafana** on top —
deployed as Helm values overlays plus dashboards and alert rules checked
in as code, instead of clicked together in the UI.

## Why

Centralized, multi-cluster observability was a recurring build across
on-prem OpenStack, Azure, and Hetzner Cloud environments. This repo
packages that pattern as something reusable: swap the S3 bucket names
and remote-write URLs, run `scripts/bootstrap.sh`, and a new cluster has
the same dashboards and alerts as every other one on day one.

## Stack

| Component  | Role                                              |
|------------|---------------------------------------------------|
| Prometheus | In-cluster scraping, short local retention        |
| Mimir      | Long-term, horizontally scalable metrics storage   |
| Alloy      | Unified agent — ships metrics + logs from every node |
| Loki       | Log aggregation, queried alongside metrics in Grafana |
| Grafana    | Dashboards + Explore + Alertmanager UI             |

## Structure

```
helm/        Helm values overlays for each component (installed against upstream charts)
dashboards/  Grafana dashboards as JSON, provisioned automatically
alerts/      PrometheusRule manifests — SLO-shaped alerts, not raw thresholds
scripts/     bootstrap.sh — one-shot install of the whole stack
docs/        Architecture notes
```

## Usage

```bash
# points at whatever cluster your current kubeconfig context is
./scripts/bootstrap.sh
```

This installs everything into the `monitoring` namespace using the
values files in `helm/`. Before running against a real cluster, replace
the placeholder S3 bucket names in `helm/values-mimir.yaml` and
`helm/values-loki.yaml`.

Dashboards in `dashboards/` are auto-provisioned by the Grafana Helm
release (see `dashboardProviders` in `helm/values-grafana.yaml`) — edit
the JSON, `helm upgrade`, and the change shows up without touching the
Grafana UI.

## Alerting

`alerts/prometheus-rules.yaml` covers node saturation, pod crash loops,
deployment replica mismatches, PV space, and API server error rate —
each with a `for:` window tuned to avoid paging on noise. Apply on their
own with:

```bash
kubectl apply -f alerts/prometheus-rules.yaml
```

## Related repos

- [`terraform-multicloud-infra`](https://github.com/jnnishad/terraform-multicloud-infra) — provisions the clusters this stack runs on
- [`gitops-cicd-pipelines`](https://github.com/jnnishad/gitops-cicd-pipelines) — how changes to this repo get deployed safely

## License

MIT — see [LICENSE](LICENSE).
