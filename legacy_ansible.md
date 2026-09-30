# Legacy Ansible-Only Deployment

> **⚠️ WARNING: Legacy/Manual Path**
>
> This document describes the **full Ansible-only deployment** for all 11 playbooks (01-11). This path is **no longer the recommended flow**.
>
> **Current primary path:**
> - **Phase 1 (Bootstrap):** Ansible playbooks 01-02.5 (HAProxy, MariaDB, K3s, kubeconfig)
> - **Phase 2 (Services):** Terraform modules for playbooks 03-11 (see [README.md](./README.md#terraform-primary-service-path))
>
> This document is preserved for reference, historical context, and manual deployment scenarios only.

---

## Overview

The legacy Ansible-only deployment installs the complete platform using 11 sequential playbooks:

1. **Infrastructure bootstrap** (01-02.5): HAProxy, MariaDB, K3s, kubeconfig
2. **Platform services** (03-11): Traefik, MetalLB, Longhorn, Prometheus, Loki, ArgoCD, External DB, Fission, External Secrets

All playbooks run from the `ansible/` directory using SSH for infrastructure and kubeconfig for cluster services.

---

## Prerequisites

### Control node

- `ansible-core >= 2.15`
- `helm`
- `kubectl`
- Ansible collections:

```bash
ansible-galaxy collection install community.docker kubernetes.core
```

### Infrastructure

- One Ubuntu-based **LXC container** with root SSH access (for HAProxy + MariaDB)
- Ubuntu **VM nodes** with SSH access and passwordless sudo (for K3s masters + workers)
- Control node with SSH access to all infrastructure nodes

---

## Local configuration

Create local configuration files from examples:

```bash
# Inventory and host variables
cp ansible/inventory/homelab/vars/local.yml.example ansible/inventory/homelab/vars/local.yml
cp ansible/inventory/homelab/hosts.ini.example ansible/inventory/homelab/hosts.ini
cp ansible/inventory/homelab/host_vars/docker-host.yml.example ansible/inventory/homelab/host_vars/docker-host.yml
```

### Edit `local.yml`

Set values such as:

- `vm_username` — SSH username for VM nodes
- `ansible_become_password` — sudo password (if not using `--ask-become-pass`)

### Edit `hosts.ini`

Set `ansible_host` for:

- `docker_host` — LXC container IP
- `masters` — K3s master node IPs
- `workers` — K3s worker node IPs

### Edit `host_vars/docker-host.yml`

Set values such as:

- `ansible_user` — SSH user for LXC container
- `docker_users` — users to add to docker group
- `docker_host_ip` — LXC container IP (used by HAProxy)

---

## Deployment order (all 11 playbooks)

Run playbooks in sequence from `ansible/` directory:

### Phase 1 — Infrastructure bootstrap (SSH)

```bash
# Step 1: Deploy HAProxy + MariaDB on Docker in LXC
ansible-playbook playbooks/01-infra.yml

# Step 2: Install K3s on master and worker nodes
ansible-playbook playbooks/02-k3s.yml

# Step 2.5: Fetch kubeconfig to control node (~/.kube/config)
ansible-playbook playbooks/02.5-kubeconfig.yml
```

**Auth:** Steps 1-2 use root SSH + sudo. Step 2.5 uses SSH + sudo to fetch and patch kubeconfig.

### Phase 2 — Platform services (kubeconfig)

```bash
# Step 3: Install Traefik ingress controller
ansible-playbook playbooks/03-traefik.yml

# Step 4: Install MetalLB load balancer
ansible-playbook playbooks/04-metallb.yml

# Step 5: Install Longhorn distributed storage
ansible-playbook playbooks/05-longhorn.yml

# Step 6: Install Prometheus monitoring stack
ansible-playbook playbooks/06-prometheus.yml

# Step 7: Install Loki log aggregation
ansible-playbook playbooks/07-loki.yml

# Step 8: Install ArgoCD GitOps
ansible-playbook playbooks/08-argocd.yml

# Step 9: Deploy external database Services/EndpointSlices (configurable)
ansible-playbook playbooks/09-external-db.yml

# Step 10: Install Fission FaaS
ansible-playbook playbooks/10-fission.yml

# Step 11: Install External Secrets Operator + AWS provider (ClusterSecretStore)
ansible-playbook playbooks/11-external-secrets.yml
```

**Auth:** Steps 3-11 run on localhost using kubeconfig (fetched in step 2.5).

If you are not using values from `local.yml`, add `--ask-become-pass` where needed.

---

## Playbook details

| Step | Playbook | Purpose | Auth |
|---|---|---|---|
| 1 | `playbooks/01-infra.yml` | Deploy HAProxy and MariaDB on Docker in LXC host | Root SSH |
| 2 | `playbooks/02-k3s.yml` | Install K3s on master and worker nodes | SSH + sudo |
| 2.5 | `playbooks/02.5-kubeconfig.yml` | Fetch kubeconfig to control node | SSH + sudo |
| 3 | `playbooks/03-traefik.yml` | Install Traefik ingress controller | Localhost / kubeconfig |
| 4 | `playbooks/04-metallb.yml` | Install MetalLB | Localhost / kubeconfig |
| 5 | `playbooks/05-longhorn.yml` | Install Longhorn | Localhost / kubeconfig |
| 6 | `playbooks/06-prometheus.yml` | Install Prometheus monitoring | Localhost / kubeconfig |
| 7 | `playbooks/07-loki.yml` | Install Loki logging | Localhost / kubeconfig |
| 8 | `playbooks/08-argocd.yml` | Install ArgoCD | Localhost / kubeconfig |
| 9 | `playbooks/09-external-db.yml` | External database Services/EndpointSlices (configurable) | Localhost / kubeconfig |
| 10 | `playbooks/10-fission.yml` | Install Fission FaaS | Localhost / kubeconfig |
| 11 | `playbooks/11-external-secrets.yml` | Install External Secrets Operator + AWS provider connection (ClusterSecretStore) | Localhost / kubeconfig |

---

## External Secrets Operator (Ansible)

> **⚠️ Legacy path.** Superseded by Terraform `eso_aws_*` variables (Phase 2 primary). See [README.md — External Secrets Operator](./README.md#external-secrets-operator) for the current deployment model.

Playbook 11 (`playbooks/11-external-secrets.yml`) installs ESO and configures the AWS provider connection using keys from `ansible/inventory/homelab/vars/local.yml`. Schema documented in [`local.yml.example`](./ansible/inventory/homelab/vars/local.yml.example).

### Keys

| Key | Required | Purpose |
|-----|----------|---------|
| `eso_aws_emulator.endpoint` | no | Mode switch for ESO AWS provider (see modes below) |
| `eso_aws_credentials.access_key_id` | no | Static AWS access key (emulator mode) |
| `eso_aws_credentials.secret_access_key` | no | Static AWS secret key (emulator mode) |
| `eso_aws_cluster_stores` | no | List of `{name, region, service}` objects. Empty = operator-only install |

#### `eso_aws_emulator.endpoint` modes

| Value | Behavior |
|-------|----------|
| Key absent | Real AWS Secrets Manager defaults. No failure. |
| Non-empty string (e.g. `http://10.27.10.38:4566`) | Emulator mode. URL must be reachable **from the cluster** (not localhost). |
| Empty string `""` | Playbook fails with clear error. Remove the key or set a real URL. |

---

## Why this path is legacy

The Ansible-only deployment was the original approach for all 11 steps. The current model splits deployment into two phases:

- **Phase 1 (Ansible):** Infrastructure bootstrap only (01-02.5)
- **Phase 2 (Terraform):** Service deployment (03-11) — **primary path**

**Benefits of Terraform for services:**

- Declarative state management
- Helm + Kubernetes providers native
- Easier drift detection and reconciliation
- Better integration with GitOps workflows

**When to use this legacy path:**

- Manual deployment scenarios
- Historical reference
- Environments where Terraform is not available
- Debugging or troubleshooting specific Ansible roles

---

## Related documentation

- [README.md](./README.md) — Current two-phase deployment model
- [legacy/](./legacy) — Previous manual installation guides and commands
- [Terraform modules](./terraform/modules/) — Phase 2 service deployment
