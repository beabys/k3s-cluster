# Plan: Ansible Migration — Step 08: ArgoCD (Final)

## Request
Automate ArgoCD GitOps installation via Helm. Ingress configured via values.yaml (`argocd.home.lab` via Traefik). No separate Ingress CRD needed.

## Reference

```bash
helm repo add argo-cd https://argoproj.github.io/argo-helm
helm upgrade --install argo-cd argo-cd/argo-cd --values ./values.yaml -n argo-cd --create-namespace
```

## Files Changed

| Path | Action |
|------|--------|
| `ansible/inventory/homelab/group_vars/all.yml` | MODIFY — 5 vars |
| `ansible/roles/argocd/defaults/main.yml` | CREATE |
| `ansible/roles/argocd/tasks/main.yml` | CREATE (Helm install) |
| `ansible/roles/argocd/meta/main.yml` | CREATE |
| `ansible/playbooks/08-argocd.yml` | CREATE |
| `ansible/test.sh` | MODIFY |

Same localhost pattern. Values file: `{{ playbook_dir }}/../../argocd/values.yaml`.

## Testing (Static Only)
- `ansible-lint .`
- `--syntax-check playbooks/08-argocd.yml`
- `./test.sh`

## Progress

- [x] 2026-06-27 — Dev done: 6 files, lint + syntax pass
- [x] 2026-06-27 — Reviewer: APPROVED
- [x] 2026-06-27 — QA: PASSED — final step, all 8 playbooks clean
- [x] 2026-06-27 — Final migration report delivered
