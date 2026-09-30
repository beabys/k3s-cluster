# k3s-cluster

Two-phase homelab K3s platform on Proxmox: Ansible bootstraps the cluster (external HAProxy + MariaDB + K3s), Terraform deploys platform services for ingress, storage, observability, logging, and GitOps.

This repository is designed as a reproducible platform engineering lab: bootstrap the cluster, layer in core services, and operate it like a small self-hosted platform.

## Overview

This project provisions and configures a K3s-based Kubernetes environment using a **two-phase deployment model**:

**Phase 1 — Bootstrap (Ansible, SSH):**
- External **HAProxy + MariaDB** infrastructure on LXC container
- **K3s** control plane and worker nodes on Ubuntu VMs
- Kubeconfig fetch to control node

**Phase 2 — Services (Terraform, kubeconfig):**
- Core platform services deployed via Terraform modules
- Ingress, storage, observability, logging, GitOps, FaaS, secrets management

**Fresh install vs existing cluster:**
- **Fresh install:** Run Phase 1 (Ansible bootstrap) then Phase 2 (Terraform services)
- **Existing cluster:** Skip Phase 1, run Phase 2 only (Terraform)

The current setup uses:

- **Ansible** for infrastructure bootstrap (Phase 1).
- **Terraform** for service deployment (Phase 2, primary path).
- **K3s** as the Kubernetes distribution.
- **Traefik** for ingress.
- **MetalLB** for load balancing in the homelab network.
- **Longhorn** for distributed storage.
- **Prometheus** for monitoring.
- **Loki** for log aggregation.
- **ArgoCD** for GitOps-driven delivery.
- **Fission** for FaaS.
- **External Secrets Operator** for secrets management.

## Goals

- Build a repeatable self-hosted Kubernetes platform.
- Automate cluster bootstrap with Ansible (Phase 1) and service deployment with Terraform (Phase 2).
- Practice platform engineering and SRE workflows locally.
- Provide a realistic environment for observability, storage, ingress, and deployment tooling.
- Reduce manual setup by moving service installation into version-controlled Terraform modules and configuration.

## Architecture

At a high level, the cluster is composed of:

- One **LXC container** hosting external infrastructure services.
- Multiple **Ubuntu VMs** acting as K3s nodes.
- A control node running Ansible, Terraform, Helm, and kubectl.

```text
Phase 1 — Bootstrap (Ansible, SSH)
├── LXC: HAProxy + MariaDB (Docker)
└── K3s VMs
    ├── master nodes
    └── worker nodes

Phase 2 — Services (Terraform, kubeconfig)
└── K3s cluster
    ├── Traefik (ingress)
    ├── MetalLB (load balancer)
    ├── Longhorn (storage)
    ├── Prometheus (monitoring)
    ├── Loki (logging)
    ├── ArgoCD (GitOps)
    ├── External DB (EndpointSlices)
    ├── Fission (FaaS)
    └── External Secrets Operator
```

This separation keeps the datastore and load balancer outside the cluster while letting K3s focus on workload orchestration. Terraform manages services declaratively via Helm and Kubernetes providers.

## Prerequisites

### Control node

Your local machine or CI runner should have:

- `ansible-core >= 2.15`
- `helm`
- `kubectl`
- Access to the required Ansible collections:

```bash
ansible-galaxy collection install community.docker kubernetes.core
```

Your kubeconfig should point to the K3s cluster once it has been fetched.

### Infrastructure

The current documented environment expects:

- One Ubuntu-based **LXC container** with root SSH access.
- Ubuntu **VM nodes** with SSH access and passwordless sudo.

Adjust inventory and variables if your homelab layout changes.

## Repository structure

```text
.
├── ansible/                # Phase 1 bootstrap automation (Ansible)
│   ├── inventory/          # Inventory and host variables
│   ├── playbooks/          # Ordered playbooks for infra bootstrap
│   └── ...
├── terraform/              # Phase 2 service deployment (Terraform, primary path)
│   ├── modules/           # One module per component (9 modules)
│   ├── main.tf
│   ├── variables.tf       # Single source of truth for all variables
│   ├── terraform_example.tfvars
│   └── Makefile
├── legacy/                 # Previous manual installation guides and commands
├── legacy_ansible.md       # Full Ansible-only deployment (legacy/manual path)
├── CONFIGURATION.md        # Detailed configuration reference (two layers, all variables)
├── .ansible-lint           # Linting rules
└── README.md
```

## Deployment order

The cluster is installed in two phases. **Phase 1** (Ansible bootstrap) runs over SSH for infrastructure setup. **Phase 2** (Terraform services) runs against the cluster through kubeconfig.

### Phase 1 — Bootstrap (Ansible, SSH)

**Optional for existing cluster:** If K3s is already running and kubeconfig is present, skip to Phase 2.

| Step | Playbook | Purpose | Auth |
|---|---|---|---|
| 1 | `playbooks/01-infra.yml` | Deploy HAProxy and MariaDB on Docker in the LXC host | Root SSH |
| 2 | `playbooks/02-k3s.yml` | Install K3s on master and worker nodes | SSH + sudo |
| 2.5 | `playbooks/02.5-kubeconfig.yml` | Fetch kubeconfig to the control node (`~/.kube/config`) | SSH + sudo |

**Note:** Step 2.5 is needed only when local kubeconfig is absent. Terraform `providers.tf` uses default `~/.kube/config` for helm+kubernetes providers.

### Phase 2 — Services (Terraform, kubeconfig)

Terraform deploys 9 modules (mapping to legacy Ansible playbooks 03-11):

| Module | Legacy Playbook | Purpose |
|---|---|---|
| `traefik` | `03-traefik.yml` | Ingress controller |
| `metallb` | `04-metallb.yml` | Load balancer |
| `longhorn` | `05-longhorn.yml` | Distributed storage |
| `prometheus` | `06-prometheus.yml` | Monitoring |
| `loki` | `07-loki.yml` | Log aggregation |
| `argocd` | `08-argocd.yml` | GitOps |
| `external-db` | `09-external-db.yml` | External database Services/EndpointSlices |
| `fission` | `10-fission.yml` | FaaS |
| `external-secrets` | `11-external-secrets.yml` | External Secrets Operator + AWS provider |

## Setup

Detailed configuration reference: [`CONFIGURATION.md`](./CONFIGURATION.md)

Create local configuration first:

```bash
cp ansible/inventory/homelab/vars/local.yml.example ansible/inventory/homelab/vars/local.yml
cp ansible/inventory/homelab/hosts.ini.example ansible/inventory/homelab/hosts.ini  
cp ansible/inventory/homelab/host_vars/docker-host.yml.example ansible/inventory/homelab/host_vars/docker-host.yml
```

Edit `local.yml` and set values such as:

- `vm_username`
- `ansible_become_password`

Then edit `hosts.ini` and set values such as:

- `ansible_host`

for `docker_host`, `masters` and `workers`

Finally edit `docker-host.yml` and set values as:

- `ansible_user`
- `docker_users`
- `docker_host_ip`

## Run the deployment

### Phase 1 — Bootstrap (fresh install only)

**Skip this phase if cluster already running.** Run from `ansible/` directory:

```bash
# Step 1: Deploy HAProxy + MariaDB on LXC
ansible-playbook playbooks/01-infra.yml

# Step 2: Install K3s on masters + workers
ansible-playbook playbooks/02-k3s.yml

# Step 2.5: Fetch kubeconfig to control node (optional if kubeconfig already present)
ansible-playbook playbooks/02.5-kubeconfig.yml
```

If you are not using values from `local.yml`, add `--ask-become-pass` where needed.

### Phase 2 — Services (primary path)

From `terraform/` directory:

```bash
# Initialize Terraform
cd terraform && terraform init

# Preview changes
make plan

# Apply (requires kubeconfig pointing to cluster)
make apply
```

### Legacy Ansible path (manual, not recommended)

Full Ansible-only deployment (playbooks 01-11) documented in [`legacy_ansible.md`](./legacy_ansible.md). This path is preserved for reference but **Terraform is the primary path for services**.

## External Secrets Operator

The Terraform module `external-secrets` installs the External Secrets Operator (ESO, chart `external-secrets/external-secrets`, namespace `external-secrets`) and exposes the **AWS provider connection only** — a credentials Secret `eso-aws-creds` plus one `ClusterSecretStore` per `eso_aws_cluster_stores` entry. This repo does **not** create consumer namespaces, `ExternalSecret`s, or demo resources; those belong in the consuming service repos.

Configuration lives in `terraform/terraform.tfvars` (gitignored — never commit credentials); the full schema is documented in [`CONFIGURATION.md`](./CONFIGURATION.md). The main keys:

- `eso_aws_emulator_endpoint` — mode switch. **Empty** (default) → real AWS Secrets Manager defaults. **Set to a URL** → emulator mode (base URL must be reachable from the cluster).
- `eso_install_crds` — whether to install ESO CRDs (default `true`).
- `eso_aws_access_key_id` / `eso_aws_secret_access_key` — static AWS credentials used against the emulator.
- `eso_aws_cluster_stores` — list of `{name, region, service}` objects; one `ClusterSecretStore` (AWS SecretsManager) per entry. A creds Secret `eso-aws-creds` is created in the `external-secrets` namespace and referenced from every store's `auth.secretRef`. Empty list → operator-only install (no provider connection).

When the emulator is in use (endpoint set), the ESO controller pod gets `AWS_SECRETSMANAGER_ENDPOINT` pointing at it, so all configured stores use the same emulator. No emulator is deployed by this repo — it runs out of cluster.

**Boundary:** consuming service repos own their Namespace and the `ExternalSecret` that references one of the stores above. Reference the cluster-wide store and follow the remote key convention `<svc>/<env>/<name>` with a JSON blob payload:

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: <es-name>
  namespace: <service-namespace>
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: eso-aws            # = eso_aws_cluster_stores entry name
  target:
    name: <target-secret>
    creationPolicy: Owner
  dataFrom:
    - extract:
        key: <svc>/<env>/<name>   # e.g. authorizer/prod/db
```

## Exposed services

The current cluster exposes the following service endpoints:

| Service | Domain | Namespace |
|---|---|---|
| Traefik Dashboard | `traefik.your.domain` | `traefik` |
| Longhorn UI | `longhorn.your.domain` | `longhorn-system` |
| Prometheus | `prometheus.your.domain` | `monitoring` |
| Alertmanager | `alertmanager.your.domain` | `monitoring` |
| Loki | `loki.your.domain` | `grafana-loki` |
| ArgoCD | `argocd.your.domain` | `argo-cd` |
| Fission Functions | `functions.your.domain` | `fission` |

Sample Fission function is reachable at `http://functions.your.domain/hello` via an HTTPTrigger (Fission v1.27 routes functions only through HTTPTriggers; the `/fission-function/*` URL is internal-only). DNS and the external reverse proxy for `functions.your.domain` must point to the cluster Traefik entrypoint — that mapping lives outside this repo (homelab router).

## Operational focus

This repository is not only about installation. It is also a place to practice platform operations such as:

- Cluster bootstrap and re-bootstrap.
- Ingress and load-balancer setup.
- Persistent storage management.
- Monitoring and log collection.
- GitOps-based cluster application delivery.
- Moving from manual steps to repeatable automation.

## Observability and reliability

The current stack already includes two important operational pillars:

- **Prometheus** for cluster and service monitoring.
- **Loki** for centralized log aggregation.

That makes this repository a strong base for expanding into SRE-oriented practices such as:

- Service-level indicators (latency, availability, error rate).
- Alert tuning and noise reduction.
- Incident runbooks.
- Failure testing and recovery documentation.

## Terraform (Primary service path)

Terraform is the **primary path** for deploying platform services (Phase 2). It deploys the same 9 components as legacy Ansible playbooks 03-11, managed declaratively via Helm and Kubernetes providers.

### Prerequisites

```bash
terraform >= 1.5
helm
kubectl
```

### Setup (3 steps)

```bash
# 1. Copy example vars
cp terraform/terraform_example.tfvars terraform/terraform.tfvars

# 2. Edit terraform.tfvars with your values:
#    - domain, metallb_ip_pool_range, all *._domain variables
#    - traefik_dashboard_password
#    - eso_aws_* if using External Secrets with AWS

# 3. Initialize
cd terraform && terraform init
```

### Usage

```bash
cd terraform

# Preview changes
make plan

# Apply (requires kubeconfig pointing to cluster)
make apply

# Destroy
make destroy
```

### Files

- `terraform/terraform.tfvars` — personal values, gitignored, contains secrets
- `terraform/terraform_example.tfvars` — committed template with placeholder values
- `terraform/secrets.tfvars` — no longer used (secrets in terraform.tfvars now)

### Migration note

- Terraform deploys the same 9 components as Ansible playbooks 03-11
- MetalLB restart Traefik automatically after apply
- Fission CRDs applied via local-exec (kubectl --server-side)
- ESO ClusterSecretStore created only when `eso_aws_cluster_stores` is non-empty

## Legacy notes

Older manual setup commands and guides are preserved in [`legacy/`](./legacy). Full Ansible-only deployment (all playbooks 01-11) documented in [`legacy_ansible.md`](./legacy_ansible.md) — **legacy/manual path, no longer recommended**.

## Why this project matters

This repository demonstrates:

- Practical Kubernetes platform work beyond local single-node experimentation.
- Ansible for infrastructure bootstrap and Terraform for platform service deployment.
- Integration of ingress, storage, monitoring, logging, and GitOps in one environment.
- A solid self-hosted lab for building SRE and platform engineering experience.

## Roadmap

Planned or sensible next improvements include:

- [ ] Add architecture diagrams.
- [ ] Document inventory layout and host roles in more detail.
- [ ] Add runbooks for common operations and failures.
- [ ] Add backup and restore procedures for MariaDB, Longhorn, and cluster state.
- [ ] Add alert rules and example SLOs for hosted workloads.
- [ ] Add CI checks for playbook validation and linting.
- [ ] Document upgrade procedures for K3s and platform services.

## Related projects

- [`proxmox-terraform`](https://github.com/beabys/proxmox-terraform) for provisioning the VM and LXC foundation used by the homelab.
