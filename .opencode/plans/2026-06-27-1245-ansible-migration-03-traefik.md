# Plan: Ansible Migration — Step 03: Traefik via Helm

## Request
Automate Traefik Ingress controller installation via Helm on K3s. Includes dashboard with basic auth. Depends on Step 02 (K3s cluster running).

## Reference (from `traefik/Readme.md`)

```bash
# Install
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik -n traefik --create-namespace

# Configure dashboard (Option A — Helm values, recommended)
helm upgrade traefik traefik/traefik -n traefik -f values.yaml

# Create auth secret + apply CRD
htpasswd -nb admin admin | kubectl -n traefik create secret generic traefik-dashboard-auth --from-file=users=/dev/stdin
kubectl apply -f traefik-dashbord-crd.yml
```

## Architecture

**Important change:** Unlike Steps 01-02 which ran on remote hosts via SSH, Step 03 runs **locally on the control node** (your Mac). Reason: `helm` + `kubectl` use local kubeconfig to talk to the K3s cluster API. No SSH into K3s nodes needed.

Playbook targets: `localhost` (control node).

## Files Changed

| Path | Action | Reason |
|------|--------|--------|
| `ansible/inventory/homelab/group_vars/all.yml` | MODIFY | Add Traefik vars (user, password, domain) |
| `ansible/inventory/homelab/group_vars/all.yml` | MODIFY | Add `kubernetes.core` requirements note |
| `ansible/roles/traefik/defaults/main.yml` | CREATE | Role defaults |
| `ansible/roles/traefik/tasks/main.yml` | CREATE | Add repo → install Helm → create secret → apply CRD |
| `ansible/roles/traefik/files/dashboard-crd.yml` | COPY | Copy from `traefik/traefik-dashbord-crd.yml` |
| `ansible/roles/traefik/meta/main.yml` | CREATE | Role metadata |
| `ansible/playbooks/03-traefik.yml` | CREATE | Playbook targeting localhost |
| `ansible/requirements.yml` | MODIFY | Add `kubernetes.core` collection |
| `ansible/test.sh` | MODIFY | Add 03-traefik syntax check |

## Implementation Steps

### Step 1 — Update group_vars/all.yml
Append:
```yaml
# Traefik
traefik_namespace: traefik
traefik_chart: traefik/traefik
traefik_repo_url: https://traefik.github.io/charts
traefik_release_name: traefik
traefik_dashboard_user: admin
traefik_dashboard_password: admin
traefik_dashboard_domain: "traefik.{{ domain }}"
# Paths relative to repo root (traefik/ directory)
traefik_values_file: "{{ playbook_dir }}/../traefik/values.yaml"
traefik_crd_source: "{{ playbook_dir }}/../traefik/traefik-dashbord-crd.yml"
```

### Step 2 — Update requirements.yml
Add `kubernetes.core` to collections:
```yaml
collections:
  - name: community.docker
    version: ">=3.0.0"
  - name: kubernetes.core
    version: ">=3.0.0"
```

### Step 3 — Create traefik role

#### `roles/traefik/defaults/main.yml`
```yaml
---
traefik_namespace: traefik
traefik_chart: traefik/traefik
traefik_repo_url: https://traefik.github.io/charts
traefik_release_name: traefik
traefik_dashboard_user: admin
traefik_dashboard_password: admin
traefik_dashboard_domain: "traefik.home.lab"
traefik_values_file: ""
traefik_crd_source: ""
```

#### `roles/traefik/tasks/main.yml`
Tasks:

1. **Ensure local prerequisites** — Check that `helm` and `kubectl` binaries exist on control node. Fail with clear message if missing.

2. **Add Traefik Helm repository** — `kubernetes.core.helm_repository`:
   - name: `traefik`
   - repo_url: `{{ traefik_repo_url }}`

3. **Install/Upgrade Traefik Helm chart** — `kubernetes.core.helm`:
   - release_name: `{{ traefik_release_name }}`
   - chart_ref: `{{ traefik_chart }}`
   - release_namespace: `{{ traefik_namespace }}`
   - create_namespace: true
   - chart_version: "" (latest)
   - values_files: `[ "{{ traefik_values_file }}" ]` (points to repo's `traefik/values.yaml`)

4. **Generate htpasswd string** — Use `community.general.htpasswd` or fallback to `htpasswd` command:
   - If `htpasswd` binary exists on control node, use shell: `htpasswd -nb {{ user }} {{ password }}`
   - Store result in a variable

5. **Create dashboard auth secret** — `kubernetes.core.k8s`:
   - state: present
   - definition:
     ```yaml
     apiVersion: v1
     kind: Secret
     metadata:
       name: traefik-dashboard-auth
       namespace: "{{ traefik_namespace }}"
     data:
       users: "{{ htpasswd_output | b64encode }}"
     ```
   (Note: if htpasswd_output is already base64-encoded by htpasswd -nb, adjust)

6. **Apply Middleware + IngressRoute CRDs** — `kubernetes.core.k8s`:
   - state: present
   - src: `{{ traefik_crd_source }}`

### Step 4 — Copy CRD file into role
Copy `traefik/traefik-dashbord-crd.yml` → `ansible/roles/traefik/files/dashboard-crd.yml` so the role is self-contained. Or reference the file from the repo root. Best: use `src` parameter pointing to the original file path relative to playbook.

### Step 5 — Create playbook `03-traefik.yml`
```yaml
---
- name: Deploy Traefik Ingress controller
  hosts: localhost
  connection: local
  roles:
    - role: traefik
```

## Key Design Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Play target | `localhost` | Helm + kubectl use local kubeconfig |
| Kubeconfig | From `~/.kube/config` (default) | User sets up after Step 02 |
| Dashboard auth | `htpasswd -nb` shell | Simple, no extra Python deps |
| Secret creation | `kubernetes.core.k8s` with data dict | Avoids shell kubectl |
| Values file | Reference original `traefik/values.yaml` | Keeps values in one place |

## Prerequisites on Control Node

- `helm` binary installed
- `kubectl` binary installed
- `~/.kube/config` pointing to K3s cluster
- `kubernetes.core` collection (`ansible-galaxy collection install kubernetes.core`)

## Testing (Static Analysis Only — No Real Execution)

- **Syntax check:** `ansible-playbook ansible/playbooks/03-traefik.yml --syntax-check`
- **Lint:** `ansible-lint ansible/`
- **Playbook structure:** `--list-hosts` + `--list-tasks`
- **Variables:** Verify all vars resolve
- **No E2E** — Would require running K3s cluster (user constraint)

## Risks / Open Questions

1. **Kubeconfig location** — User must have `~/.kube/config` set up from Step 02. The playbook uses default kubeconfig from `kubernetes.core` modules. Not configurable in v1.
2. **`htpasswd` binary** — Not installed by default on macOS. May need `brew install httpd` or use Python `passlib` hashing. Fallback: use `openssl passwd` or Ansible's `password_hash` filter.
3. **Values file path** — `traefik_values_file` uses `playbook_dir` relative path. May need adjustment if playbook is run from different directories.
4. **Secret idempotency** — `kubernetes.core.k8s` with `state: present` handles create/update. The htpasswd content determines if update needed.

## Progress

- [x] 2026-06-27 — Dev done: 8 files created/modified, lint + syntax pass
- [x] 2026-06-27 — Reviewer: REJECTED — 4 issues (path depth x2, crypt broken, unused file)
- [x] 2026-06-27 — Dev round 2: fixed all 4 issues
- [x] 2026-06-27 — Reviewer re-review: APPROVED
- [x] 2026-06-27 — QA: PASSED (static analysis) — all 7 plan requirements validated
- [x] 2026-06-27 — Final report delivered
