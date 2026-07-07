# Architecture

```
 every node/pod
      │  metrics + logs + traces
      ▼
  Alloy (DaemonSet)
      │            │
      ▼            ▼
   Mimir         Loki
 (metrics,     (logs, 3x
  3x ingest    replication)
  replication)
      │            │
      └─────┬──────┘
            ▼
        Grafana
   (dashboards, alerting via Alertmanager)
```

**Why Mimir instead of vanilla Prometheus retention:** local Prometheus
retention (15d here) is a cache, not the source of truth — `remoteWrite`
ships everything to Mimir, which is horizontally scalable and gives
months of queryable history without growing PVs on the Prometheus pods
themselves. This mirrors the "centralized monitoring and logging
platform for multi-cluster environments" pattern used across on-prem
OpenStack and Azure/Hetzner clusters.

**Why Alloy over Promtail + node-exporter sidecars:** Alloy replaces
several single-purpose agents (Promtail, the Prometheus Agent mode,
OTel collector) with one DaemonSet and one config language (River),
which is what actually shipped in the most recent production
environment this repo is modeled on.

**Alerting philosophy:** rules in `alerts/prometheus-rules.yaml` are
SLO-shaped (error rate, saturation, restart loops) rather than raw
threshold noise — each alert has a `for:` duration to avoid paging on
transient blips.
