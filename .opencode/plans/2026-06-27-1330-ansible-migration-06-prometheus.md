# Plan: Ansible Migration — Step 06: Prometheus

## Request
Automate Prometheus monitoring stack via Helm (`kube-prometheus-stack`). Includes Alertmanager + Prometheus UI Ingresses. Grafana disabled in values (no ingress needed).

## Reference (from `prometheus-helm/Readme.md`)

```bash
helm upgrade --install -f ./values.yaml prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
kubectl apply -f alert-manager-ingress-controller.yml
kubectl apply -f prometheus-ingress-controller.yml
```

## Architecture

Same localhost pattern (Helm + kubectl via kubeconfig). Single play.

## Files Changed

| Path | Action | Reason |
|------|--------|--------|
| `ansible/inventory/homelab/group_vars/all.yml` | MODIFY | Add Prometheus vars |
| `ansible/roles/prometheus/defaults/main.yml` | CREATE | Role defaults |
| `ansible/roles/prometheus/tasks/main.yml` | CREATE | Helm repo + install + ingress CRDs |
| `ansible/roles/prometheus/files/alertmanager-ingress.yml` | COPY | From `prometheus-helm/ingress-controllers/alert-manager-ingress-controller.yml` |
| `ansible/roles/prometheus/files/prometheus-ingress.yml` | COPY | From `prometheus-helm/ingress-controllers/prometheus-ingress-controller.yml` |
| `ansible/roles/prometheus/meta/main.yml` | CREATE | Role metadata |
| `ansible/playbooks/06-prometheus.yml` | CREATE | Playbook targeting localhost |
| `ansible/test.sh` | MODIFY | Add 06-prometheus syntax check |

## Implementation

### group_vars/all.yml — append
```yaml
# Prometheus
prometheus_namespace: monitoring
prometheus_chart: prometheus-community/kube-prometheus-stack
prometheus_repo_url: https://prometheus-community.github.io/helm-charts
prometheus_release_name: prometheus
```

### Tasks
1. Check prerequisites (helm + kubectl)
2. Add Prometheus Helm repo
3. Install/Upgrade kube-prometheus-stack chart with `values.yaml`
4. Apply Alertmanager Ingress
5. Apply Prometheus Ingress
6. (Grafana ingress skipped — Grafana disabled in values.yaml)

### Paths
- Values file: `{{ playbook_dir }}/../../prometheus-helm/values.yaml`
- Ingress files: role's `files/` directory (same pattern as previous steps)

### Notes
- `values_loki.yaml` and `values2.yaml` exist in prometheus-helm/ but are not used by default — not included
- Grafana ingress is commented out in source — not applied
- ServiceMonitor for Longhorn (`longhorn/serviceMonitor.yaml`) deferred — user can apply manually or add to future task

## Testing (Static Only)
- `ansible-lint .`
- `--syntax-check playbooks/06-prometheus.yml`
- `./test.sh`

## Progress

- [x] 2026-06-27 — Dev done: 8 files, lint + syntax pass
- [x] 2026-06-27 — Reviewer: APPROVED
- [x] 2026-06-27 — QA: PASSED — all plan requirements validated
- [x] 2026-06-27 — Final report delivered
