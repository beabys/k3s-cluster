# Plan: Ansible Migration — Step 07: Loki

## Request
Automate Loki log aggregation stack via Helm (`grafana/loki-stack`). Includes Ingress for Loki UI. Depends on Step 06 (Prometheus) for monitoring namespace.

## Reference

```bash
helm upgrade --install loki grafana/loki-stack --values ./values.yaml -n grafana-loki --create-namespace
kubectl apply -f loki-ingress-controller.yml
```

## Files Changed

| Path | Action |
|------|--------|
| `ansible/inventory/homelab/group_vars/all.yml` | MODIFY — 5 vars |
| `ansible/roles/loki/defaults/main.yml` | CREATE |
| `ansible/roles/loki/tasks/main.yml` | CREATE (Helm + ingress) |
| `ansible/roles/loki/files/loki-ingress.yml` | COPY from `loki-helm/loki-ingress-controller.yml` |
| `ansible/roles/loki/meta/main.yml` | CREATE |
| `ansible/playbooks/07-loki.yml` | CREATE |
| `ansible/test.sh` | MODIFY |

Same localhost pattern as Traefik/MetalLB/Longhorn/Prometheus.

## Testing (Static Only)
- `ansible-lint .`
- `--syntax-check playbooks/07-loki.yml`
- `./test.sh`

## Progress

- [x] 2026-06-27 — Dev done: 7 files, lint + syntax pass
- [x] 2026-06-27 — Reviewer: APPROVED
- [x] 2026-06-27 — QA: PASSED — 8/8 test.sh, all valid
- [x] 2026-06-27 — Final report delivered
