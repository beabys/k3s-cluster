# Plan: Ansible Migration — Step 01: HAProxy + MariaDB

## Request
Migrate `k3s-cluster` repo from manual README-based installation to Ansible automation. All VM/LXC provisioning stays out of scope (separate repo). This first sub-task automates HAProxy + MariaDB deployment on a **single LXC container** (the Docker host), as described in `README.md`.

## Overall Migration Strategy (all sub-tasks)

| # | Sub-task | Source | Ansible Target |
|---|----------|--------|----------------|
| 01 | **HAProxy + MariaDB** (this) | `README.md` Docker compose | Role `haproxy` + `mariadb`, one LXC host |
| 02 | K3s install (masters + agents) | `README.md` curl install | Role `k3s` |
| 03 | Traefik via Helm | `traefik/Readme.md` | Role `traefik` |
| 04 | MetalLB via Helm | `metallb/Readme.md` | Role `metallb` |
| 05 | Longhorn via Helm | `longhorn/Readme.md` | Role `longhorn` |
| 06 | Prometheus via Helm | `prometheus-helm/Readme.md` | Role `prometheus` |
| 07 | Loki via Helm | `loki-helm/Readme.md` | Role `loki` |
| 08 | ArgoCD via Helm | `argocd/Readme.md` | Role `argocd` |

Each sub-task: Dev (code + tests) → Reviewer → QA. Sequential — order matters (dependencies between services).

## Files Changed

| Path | Action | Reason |
|------|--------|--------|
| `ansible/ansible.cfg` | CREATE | Ansible config |
| `ansible/inventory/homelab/hosts.ini` | CREATE | Inventory: masters, workers, docker_host groups |
| `ansible/inventory/homelab/host_vars/docker-host.yml` | CREATE | Docker host IP (configurable) |
| `ansible/inventory/homelab/group_vars/all.yml` | CREATE | Global vars: IPs, versions, passwords, image tags |
| `ansible/playbooks/01-infra.yml` | CREATE | Playbook for infra layer (docker + haproxy + mariadb) |
| `ansible/roles/docker/defaults/main.yml` | CREATE | Docker install vars |
| `ansible/roles/docker/tasks/main.yml` | CREATE | Install Docker CE + Python SDK |
| `ansible/roles/docker/meta/main.yml` | CREATE | Role metadata |
| `ansible/roles/haproxy/defaults/main.yml` | CREATE | HAProxy variables (image tag, port, etc.) |
| `ansible/roles/haproxy/tasks/main.yml` | CREATE | Deploy HAProxy Docker container |
| `ansible/roles/haproxy/templates/haproxy.cfg.j2` | CREATE | HAProxy config template |
| `ansible/roles/haproxy/meta/main.yml` | CREATE | Role metadata (depends: docker) |
| `ansible/roles/mariadb/defaults/main.yml` | CREATE | MariaDB variables (image tag, DB name, passwords) |
| `ansible/roles/mariadb/tasks/main.yml` | CREATE | Deploy MariaDB Docker container |
| `ansible/roles/mariadb/meta/main.yml` | CREATE | Role metadata (depends: docker) |

## Implementation Steps (This Sub-task)

1. **Create Ansible directory structure** — `ansible/` with `ansible.cfg`, `inventory/`, `playbooks/`, `roles/`
2. **Create inventory** — `hosts.ini` with `[docker_host]` group, `[masters]`, `[workers]` (stubs for now). Use `host_vars/` for per-host IP.
3. **Create group_vars/all.yml** — Common vars: domain (`home.lab`), IPs (`10.27.10.x`) configurable via var, MariaDB root/user/pass, HAProxy frontend port, Docker image tags (`haproxy:latest`, `mariadb:latest`), etc.
4. **Create `docker` role** (dependency for haproxy + mariadb):
   - Install Docker CE from official repo (docker-ce, docker-ce-cli, containerd.io)
   - Install `python3-docker` / `docker` Python SDK (required by `community.docker` modules)
   - Start + enable `docker` service
   - Add `ansible_user` to `docker` group (or use socket permissions)
   - Allow skip via `docker_install: false` var if Docker already present
5. **Create `haproxy` role**:
   - Depends on `docker` role via `meta/main.yml`
   - Deploy HAProxy container with `community.docker.docker_container`:
     - Image: `haproxy:latest` (configurable)
     - Port mapping: `6443:6443`
     - Volume: bind-mount `/usr/local/etc/haproxy` with templated config
     - Restart policy: `always`
     - Memory limit: `2g`
   - Template `haproxy.cfg.j2` from README:
     - Frontend `k3s-frontend` bind `*:6443` mode tcp
     - Backend `k3s-backend` with servers from `k3s_masters` list var
   - Deploy config file before container (create dir on host, write config)
6. **Create `mariadb` role**:
   - Depends on `docker` role via `meta/main.yml`
   - Deploy MariaDB container with `community.docker.docker_container`:
     - Image: `mariadb:latest` (configurable)
     - Env vars: `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD` from vars
     - Volume: `/var/lib/mysql` data persistence
     - Port mapping: `3306:3306`
     - Command: `--innodb-buffer-pool-size=1434M`
     - Restart policy: `always`
     - Memory limit: `2g`, reservation: `1g`
7. **Create `01-infra.yml` playbook** — Apply `haproxy` + `mariadb` roles to `docker_host` group
8. **Validation** — `ansible-playbook --syntax-check`, `--check` (dry-run), verify Docker containers would deploy

## Test Plan

- **Unit:** Each role tested via `ansible-lint` (no dedicated unit test framework for Ansible, but lint catches idempotency issues)
- **Integration:** `ansible-playbook --syntax-check` + `--check` (dry-run) against localhost or a test LXC
- **E2E (QA):** Run full playbook against a real LXC container, verify `docker ps` shows both containers running, `curl` HAProxy frontend port, `mysql -h .50 -u k3s -p` connects

## Risks / Open Questions

1. ~~Docker install method~~ — **RESOLVED:** Ansible installs Docker CE via `docker` role. Skip via `docker_install: false`.
2. ~~LXC host IP~~ — **RESOLVED:** Configurable via `host_vars/docker-host.yml`. Default `10.27.10.50`.
3. ~~HAProxy backend IPs~~ — **RESOLVED:** Configurable in `group_vars/all.yml` under `k3s_masters` list. Defaults match README.
4. **Password in plaintext** — MariaDB passwords in README are plaintext (`k3spass`). For v1, keep as vars; later add ansible-vault.
5. ~~Docker compose vs raw Docker~~ — **RESOLVED:** `docker_container` module. No compose dependency.
6. **Ansible control node** — Mac for now. CI/CD pipeline later (out of scope). `ansible.cfg` will set `host_key_checking = False` for dev ergonomics.
7. **Image tags** — `haproxy:latest` and `mariadb:latest`. Configurable via vars.

## Prerequisites

- `ansible-core >= 2.15` on control node
- `community.docker` collection (`ansible-galaxy collection install community.docker`)
- SSH access to the LXC container (passwordless key or sshpass)
- Python 3 on the LXC container (LXC Ubuntu/Debian has it)

## Progress

- [x] 2026-06-27 — Dev done: 18 files created, lint + syntax-check pass
- [x] 2026-06-27 — Reviewer: REJECTED — 4 blocking issues (missing handler, deprecated modules, missing mem_reservation, unused docker_users)
- [x] 2026-06-27 — Dev round 2: fixed all 4 issues
- [x] 2026-06-27 — Reviewer re-review: APPROVED
- [x] 2026-06-27 — QA: PASSED — all static tests valid, E2E needs real LXC target
- [x] 2026-06-27 — Final report delivered to user
