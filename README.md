# k3s-cluster

Ansible-based bootstrapping for a homelab K3s cluster running on Proxmox, with external HAProxy and MariaDB, plus platform services for ingress, storage, observability, logging, and GitOps.

This repository is designed as a reproducible platform engineering lab: bootstrap the cluster, layer in core services, and operate it like a small self-hosted platform.

## Overview

This project provisions and configures a K3s-based Kubernetes environment with a clear deployment flow:

- External **HAProxy + MariaDB** infrastructure running on an LXC container.
- **K3s** control plane and worker nodes running on Ubuntu VMs.
- Core platform services deployed in sequence with Ansible.
- A path from infrastructure bootstrap to observability and GitOps.

The current setup uses:

- **Ansible** for orchestration and automation.
- **K3s** as the Kubernetes distribution.
- **Traefik** for ingress.
- **MetalLB** for load balancing in the homelab network.
- **Longhorn** for distributed storage.
- **Prometheus** for monitoring.
- **Loki** for log aggregation.
- **ArgoCD** for GitOps-driven delivery.

## Goals

- Build a repeatable self-hosted Kubernetes platform.
- Automate cluster and service setup with Ansible.
- Practice platform engineering and SRE workflows locally.
- Provide a realistic environment for observability, storage, ingress, and deployment tooling.
- Reduce manual setup by moving service installation into version-controlled playbooks.

## Architecture

At a high level, the cluster is composed of:

- One **LXC container** hosting external infrastructure services.
- Multiple **Ubuntu VMs** acting as K3s nodes.
- A control node running Ansible, Helm, and kubectl.

```text
Ansible playbooks
├── LXC: HAProxy + MariaDB
└── K3s VMs
    ├── master nodes
    ├── worker nodes
    └── platform services
        ├── Traefik
        ├── MetalLB
        ├── Longhorn
        ├── Prometheus
        ├── Loki
        └── ArgoCD
```

This separation is useful because it keeps the datastore and load balancer outside the cluster while letting K3s focus on workload orchestration.

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
├── ansible/                # Main automation entrypoint
│   ├── inventory/          # Inventory and host variables
│   ├── playbooks/          # Ordered playbooks for infra and services
│   └── ...
├── terraform/              # Terraform configuration (alternative to Ansible for playbooks 03-11)
│   ├── modules/           # One module per component
│   ├── main.tf
│   ├── variables.tf       # Single source of truth for all variables
│   ├── terraform_example.tfvars
│   └── Makefile
├── legacy/                 # Previous manual installation guides and commands
├── .ansible-lint           # Linting rules
└── README.md
```

## Deployment order

The cluster is installed in a staged sequence. Steps 1-2 run over SSH, and the remaining steps run against the cluster through kubeconfig on the control node.

| Step | Playbook | Purpose | Auth |
|---|---|---|---|
| 1 | `playbooks/01-infra.yml` | Deploy HAProxy and MariaDB on Docker in the LXC host | Root SSH |
| 2 | `playbooks/02-k3s.yml` | Install K3s on master and worker nodes | SSH + sudo |
| 2.5 | `playbooks/02.5-kubeconfig.yml` | Fetch kubeconfig to the control node | SSH + sudo |
| 3 | `playbooks/03-traefik.yml` | Install Traefik ingress controller | Localhost / kubeconfig |
| 4 | `playbooks/04-metallb.yml` | Install MetalLB | Localhost / kubeconfig |
| 5 | `playbooks/05-longhorn.yml` | Install Longhorn | Localhost / kubeconfig |
| 6 | `playbooks/06-prometheus.yml` | Install Prometheus monitoring | Localhost / kubeconfig |
| 7 | `playbooks/07-loki.yml` | Install Loki logging | Localhost / kubeconfig |
| 8 | `playbooks/08-argocd.yml` | Install ArgoCD | Localhost / kubeconfig |
| 9 | `playbooks/09-external-db.yml` | External database Services/EndpointSlices (configurable) | Localhost / kubeconfig |
| 10 | `playbooks/10-fission.yml` | Install Fission FaaS | Localhost / kubeconfig |
| 11 | `playbooks/11-external-secrets.yml` | Install External Secrets Operator + AWS provider connection (ClusterSecretStore) | Localhost / kubeconfig |

## Setup

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

From the `ansible` directory, run the playbooks in order:

```bash
ansible-playbook playbooks/01-infra.yml
ansible-playbook playbooks/02-k3s.yml
ansible-playbook playbooks/02.5-kubeconfig.yml
ansible-playbook playbooks/03-traefik.yml
ansible-playbook playbooks/04-metallb.yml
ansible-playbook playbooks/05-longhorn.yml
ansible-playbook playbooks/06-prometheus.yml
ansible-playbook playbooks/07-loki.yml
ansible-playbook playbooks/08-argocd.yml
ansible-playbook playbooks/10-fission.yml
ansible-playbook playbooks/11-external-secrets.yml
```

If you are not using values from `local.yml`, add `--ask-become-pass` where needed.

## External Secrets Operator

[Playbook 11](./ansible/playbooks/11-external-secrets.yml) installs the External Secrets Operator (ESO, chart `external-secrets/external-secrets`, namespace `external-secrets`) and exposes the **AWS provider connection only** — a credentials Secret plus one `ClusterSecretStore` per entry. This repo does **not** create consumer namespaces, `ExternalSecret`s, or demo resources; those belong in the consuming service repos.

Configuration lives in `ansible/inventory/homelab/vars/local.yml` (gitignored — never commit credentials); the schema is documented in [`local.yml.example`](./ansible/inventory/homelab/vars/local.yml.example). The main keys:

- `eso_aws_emulator` — optional `endpoint` key decides the mode. Endpoint **absent** → real AWS Secrets Manager defaults. Endpoint **set (non-empty)** → emulator mode (base URL must be reachable from the cluster). Endpoint **set to empty string** → playbook fails with a clear message.
- `eso_aws_credentials` — static `access_key_id` / `secret_access_key` used against the emulator.
- `eso_aws_cluster_stores` — one `ClusterSecretStore` (AWS SecretsManager) per entry; a creds Secret `eso-aws-creds` is created in the `external-secrets` namespace and referenced from every store's `auth.secretRef`. Empty list → operator-only install (no provider connection).

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
| Traefik Dashboard | `traefik.home.beabys.com` | `traefik` |
| Longhorn UI | `longhorn.home.beabys.com` | `longhorn-system` |
| Prometheus | `prometheus.home.beabys.com` | `monitoring` |
| Alertmanager | `alertmanager.home.beabys.com` | `monitoring` |
| Loki | `loki.home.beabys.com` | `grafana-loki` |
| ArgoCD | `argocd.home.beabys.com` | `argo-cd` |
| Fission Functions | `functions.home.beabys.com` | `fission` |

Sample Fission function is reachable at `http://functions.home.beabys.com/hello` via an HTTPTrigger (Fission v1.27 routes functions only through HTTPTriggers; the `/fission-function/*` URL is internal-only). DNS and the external reverse proxy for `functions.home.beabys.com` must point to the cluster Traefik entrypoint — that mapping lives outside this repo (homelab router).

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

## Legacy notes

Older manual setup commands and guides are preserved in [`legacy/`](./legacy). This is useful for tracking the transition from manual operations to automated provisioning.

## Why this project matters

This repository demonstrates:

- Practical Kubernetes platform work beyond local single-node experimentation.
- Automation with Ansible across both infrastructure and cluster services.
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

## Terraform (Alternative to Ansible)

Terraform is an alternative to Ansible for deploying playbooks 03-11. Both can coexist; Terraform is the future direction.

### Prerequisites

```bash
terraform >= 1.0
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

## Related projects

- [`proxmox-terraform`](https://github.com/beabys/proxmox-terraform) for provisioning the VM and LXC foundation used by the homelab.
