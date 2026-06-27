# Plan: Ansible Migration — Step 04: MetalLB

## Request
Automate MetalLB installation via Helm. Includes IP address pool + L2Advertisement. Depends on Step 02 (K3s running) + Step 03 (Traefik ingress).

## Reference (from `metallb/Readme.md`)

```bash
helm repo add metallb https://metallb.github.io/metallb
helm upgrade --install metallb metallb/metallb -n metallb-system --create-namespace
kubectl apply -f ./service-pool.yaml
```

## Files Changed

| Path | Action | Reason |
|------|--------|--------|
| `ansible/inventory/homelab/group_vars/all.yml` | MODIFY | Add MetalLB vars (namespace, repo, chart, IP pool range) |
| `ansible/roles/metallb/defaults/main.yml` | CREATE | Role defaults |
| `ansible/roles/metallb/tasks/main.yml` | CREATE | Add repo → install Helm → apply IP pool |
| `ansible/roles/metallb/files/service-pool.yaml` | COPY | From `metallb/service-pool.yaml`, make IPs templated |
| `ansible/roles/metallb/meta/main.yml` | CREATE | Role metadata |
| `ansible/playbooks/04-metallb.yml` | CREATE | Playbook targeting localhost |
| `ansible/test.sh` | MODIFY | Add 04-metallb syntax check |

## Implementation

### group_vars/all.yml — append
```yaml
# MetalLB
metallb_namespace: metallb-system
metallb_chart: metallb/metallb
metallb_repo_url: https://metallb.github.io/metallb
metallb_release_name: metallb
metallb_ip_pool_range: 10.27.10.60-10.27.10.89
```

### Tasks
1. Check prerequisites (helm + kubectl — same pattern as traefik)
2. Add MetalLB Helm repo
3. Install/Upgrade MetalLB chart
4. Apply IP pool + L2Advertisement (from role's `files/service-pool.yaml.j2` templated with `metallb_ip_pool_range`)

### Key Design

Same pattern as Traefik (Step 03):
- Playbook targets `localhost`, `connection: local`
- Uses `kubernetes.core` modules
- Service pool is templated (so IP range is configurable)
- No dashboard/auth for MetalLB — simpler than Traefik

### Testing (Static Only)
- `ansible-lint .`
- `--syntax-check playbooks/04-metallb.yml`
- `./test.sh`

## Progress

- [x] 2026-06-27 — Dev done: 7 files, lint + syntax pass
- [x] 2026-06-27 — Reviewer: APPROVED
- [x] 2026-06-27 — QA: PASSED — all 5 plan requirements validated
- [x] 2026-06-27 — Final report delivered
