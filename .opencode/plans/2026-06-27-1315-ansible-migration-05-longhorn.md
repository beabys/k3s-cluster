# Plan: Ansible Migration — Step 05: Longhorn

## Request
Automate Longhorn distributed storage installation. Includes prerequisites (open-iscsi + nfs-common via `longhornctl`), Helm install with `value.yaml`, and Ingress for UI.

## Reference (from `longhorn/Readme.md`)

### Prerequisites — via longhornctl (kubectl-based, no SSH)
```bash
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ARCH="amd64" ;;
  aarch64) ARCH="arm64" ;;
esac
curl -sSfL -o longhornctl \
  "https://github.com/longhorn/cli/releases/download/v1.12.0/longhornctl-${OS}-${ARCH}"
chmod +x longhornctl

kubectl create namespace longhorn-system
./longhornctl --kubeconfig ~/.kube/config --image longhornio/longhorn-cli:v1.12.0 install preflight
./longhornctl --kubeconfig ~/.kube/config check preflight
```

### Helm install
```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn longhorn/longhorn -f value.yaml --namespace longhorn-system --create-namespace --version 1.12.0
```

### Ingress for UI
```bash
kubectl apply -f longhorn-ingress-controller.yml
```

## Architecture — All localhost (no SSH needed)

**Both plays run on localhost** — prereqs via `longhornctl` (kubectl DaemonSet), Helm via `kubernetes.core.helm`.

| Play | Hosts | What | Method |
|------|-------|------|--------|
| Play 1: Prereqs | `localhost` | Download longhornctl + run preflight | `shell` + `k8s` |
| Play 2: Helm | `localhost` | Add repo + install chart + apply ingress | `kubernetes.core.helm` + `k8s` |

## Files Changed

| Path | Action | Reason |
|------|--------|--------|
| `ansible/inventory/homelab/group_vars/all.yml` | MODIFY | Add Longhorn vars (chart, namespace, version, domain) |
| `ansible/roles/longhorn/defaults/main.yml` | CREATE | All vars (prereq + helm) |
| `ansible/roles/longhorn/tasks/main.yml` | CREATE | Download longhornctl → preflight → helm → ingress |
| `ansible/roles/longhorn/files/ingress.yml` | COPY | From `longhorn/longhorn-ingress-controller.yml` |
| `ansible/roles/longhorn/meta/main.yml` | CREATE | Role metadata |
| `ansible/playbooks/05-longhorn.yml` | CREATE | 2 plays, both localhost |
| `ansible/test.sh` | MODIFY | Add 05-longhorn syntax check |

## Implementation

### group_vars/all.yml — append
```yaml
# Longhorn
longhorn_namespace: longhorn-system
longhorn_chart: longhorn/longhorn
longhorn_repo_url: https://charts.longhorn.io
longhorn_release_name: longhorn
longhorn_version: 1.12.0
longhorn_domain: "longhorn.{{ domain }}"
```

### Tasks (all in one `longhorn` role, two plays in playbook)

**Play 1 tasks (localhost):**
1. Detect OS + arch (set_fact)
2. Download longhornctl binary from GitHub releases
3. Make it executable
4. Ensure longhorn-system namespace exists (k8s module)
5. Run `longhornctl install preflight` (shell, waits for DaemonSet completion)
6. Run `longhornctl check preflight` (shell, verify)

**Play 2 tasks (localhost):**
1. Check prerequisites (helm + kubectl)
2. Add Longhorn Helm repo
3. Install/Upgrade Longhorn chart with `value.yaml`
4. Apply Ingress from role's `files/ingress.yml`

### Playbook structure
```yaml
- name: Install Longhorn prerequisites via longhornctl
  hosts: localhost
  connection: local
  roles:
    - role: longhorn
      vars:
        longhorn_phase: prereq

- name: Deploy Longhorn via Helm
  hosts: localhost
  connection: local
  roles:
    - role: longhorn
      vars:
        longhorn_phase: helm
```

Or simpler — inline tasks in playbook for prereq, role for helm. Recommend: separate into two roles `longhorn_prereq` and `longhorn` for clarity, or use `longhorn_phase` var to gate tasks.

**Recommended approach:** Single `longhorn` role with `longhorn_phase` var (`prereq` or `helm`). Tasks gated by `when: longhorn_phase == "prereq"` etc.

### Paths
- `value.yaml`: `{{ playbook_dir }}/../../longhorn/value.yaml`
- Ingress file: `ingress.yml` (role's `files/` directory)

### Skipped
- `serviceMonitor.yaml` — applied during Prometheus step (depends on prometheus operator)
- Flannel fix — already done in Step 02

## Testing (Static Only)
- `ansible-lint .`
- `--syntax-check playbooks/05-longhorn.yml`
- `--list-hosts` + `--list-tasks`
- `./test.sh`

## Progress

- [x] 2026-06-27 — Dev done: 7 files, lint + syntax pass
- [x] 2026-06-27 — Reviewer: APPROVED (cosmetic YAML indent only)
- [x] 2026-06-27 — QA: PASSED — all 7 plan requirements validated
- [x] 2026-06-27 — Final report delivered
