# Configuration Reference

Two-layer configuration for the k3s-cluster homelab platform. Each layer maps to one deployment phase.

| Layer | Phase | Tool | Config base | Purpose |
|-------|-------|------|-------------|---------|
| **A** | Phase 1 — Bootstrap | Ansible (SSH) | `ansible/inventory/homelab/` | Infra: HAProxy, MariaDB, K3s install |
| **B** | Phase 2 — Services | Terraform (kubeconfig) | `terraform/` | Platform services via Helm |

Layer A builds the cluster. Layer B deploys services onto it. Both layers must agree on `domain`, `metallb_ip_pool_range`, and the docker-host IP.

---

## Quick start (minimal required config)

### Layer A — three files to create

```bash
cp ansible/inventory/homelab/hosts.ini.example       ansible/inventory/homelab/hosts.ini
cp ansible/inventory/homelab/vars/local.yml.example   ansible/inventory/homelab/vars/local.yml
cp ansible/inventory/homelab/host_vars/docker-host.yml.example \
   ansible/inventory/homelab/host_vars/docker-host.yml
```

Minimum edits:

1. `hosts.ini` — fill every `ansible_host=` with real IP.
2. `local.yml` — set `vm_username` (required).
3. `docker-host.yml` — set `docker_host_ip` (required — feeds K3s datastore endpoint, TLS SAN, k3s server URL, kubeconfig patch).

### Layer B — one file to create

```bash
cp terraform/terraform_example.tfvars terraform/terraform.tfvars
cd terraform && terraform init
```

Minimum edits in `terraform.tfvars`:

1. `domain` — base DNS domain.
2. `metallb_ip_pool_range` — must match Layer A if overridden.
3. `traefik_dashboard_password` — change from default.
4. All `*_domain` vars — if non-default domain used.

---

## Layer A — Phase 1 bootstrap (Ansible inventory)

Base path: `ansible/inventory/homelab/`

### File layout

```text
ansible/inventory/homelab/
├── hosts.ini                  # gitignored — copy from hosts.ini.example
├── hosts.ini.example          # committed template
├── vars/
│   ├── local.yml              # gitignored — copy from local.yml.example
│   └── local.yml.example      # committed template
├── host_vars/
│   ├── docker-host.yml        # gitignored — copy from docker-host.yml.example
│   └── docker-host.yml.example
└── group_vars/
    ├── all.yml                # committed defaults (do not edit by hand)
    ├── masters.yml            # committed
    └── workers.yml            # committed
```

### `hosts.ini`

Defines three host groups. Each host needs `ansible_host=` set to its reachable IP.

```ini
[docker_host]
docker-host ansible_host=10.27.10.50

[masters]
k3s-m1 ansible_host=10.27.10.51
k3s-m2 ansible_host=10.27.10.52

[workers]
k3s-w1 ansible_host=10.27.10.53
k3s-w2 ansible_host=10.27.10.54
```

Groups:

- `[docker_host]` — LXC container running HAProxy + MariaDB. Exactly one entry.
- `[masters]` — K3s control-plane nodes. One or more.
- `[workers]` — K3s worker nodes. Zero or more.

### `vars/local.yml`

User overrides and secrets. Loaded via `vars_files` in playbooks; overrides `group_vars/all.yml`.

```yaml
---
# SSH user for masters and workers (VM username) — REQUIRED
vm_username: "beabys"

# Sudo password — optional; omit and use --ask-become-pass or ANSIBLE_BECOME_PASSWORD env
# ansible_become_password: "your-sudo-password"

# Infrastructure overrides (uncomment to change from group_vars/all.yml defaults)
# domain: your.domain
# metallb_ip_pool_range: 10.27.10.60-10.27.10.89

# External databases — expose external DBs as Services/EndpointSlices in-cluster
external_databases:
  - namespace: databases
    database_name: mysql
    database_internal_port: 3306
    database_host_port: 3306
    database_host: 10.27.10.37
  - namespace: databases
    database_name: postgresql
    database_internal_port: 5432
    database_host_port: 5432
    database_host: 10.27.10.37

# External Secrets Operator — AWS emulator endpoint
# endpoint ABSENT        -> real AWS Secrets Manager defaults
# endpoint non-empty     -> emulator mode (must be reachable FROM CLUSTER)
# endpoint empty string  -> playbook fails
eso_aws_emulator:
  endpoint: "http://10.27.10.38:4566"

# Static AWS credentials for emulator (gitignored file — secrets stay local)
eso_aws_credentials:
  access_key_id: "test"
  secret_access_key: "test"

# Cluster-wide SecretStores (AWS SecretsManager). Empty = operator-only install.
# Each entry: name (DNS-1123), region (default us-east-1), service (default SecretsManager)
eso_aws_cluster_stores:
  - name: eso-aws
    region: us-east-1
    service: SecretsManager
```

Key reference:

| Key | Required | Purpose |
|-----|----------|---------|
| `vm_username` | **yes** | SSH user for `[masters]` and `[workers]` groups |
| `ansible_become_password` | no | Sudo password; alternative: `--ask-become-pass` or env `ANSIBLE_BECOME_PASSWORD` |
| `domain` | no | Override base DNS domain (default: `your.domain`; set in gitignored `vars/local.yml` copied from `local.yml.example`, which ships `domain: your.domain` — edit to your real domain) |
| `metallb_ip_pool_range` | no | Override MetalLB IP pool (default: `10.27.10.60-10.27.10.89`) |
| `external_databases` | no | List of external DBs to expose as in-cluster Services. Empty = no Services created |
| `eso_aws_emulator.endpoint` | no | Mode switch for ESO AWS provider (see modes below) |
| `eso_aws_credentials` | no | Static creds for emulator mode |
| `eso_aws_cluster_stores` | no | List of `ClusterSecretStore` resources. Empty = operator-only install |

#### `eso_aws_emulator.endpoint` modes

| Value | Behavior |
|-------|----------|
| Key absent | Real AWS Secrets Manager defaults. No failure. |
| Non-empty string (e.g. `http://10.27.10.38:4566`) | Emulator mode. URL must be reachable **from the cluster** (not localhost). |
| Empty string `""` | Playbook fails with clear error. Remove the key or set a real URL. |

#### `external_databases` entry schema

| Key | Type | Purpose |
|-----|------|---------|
| `namespace` | string | Kubernetes namespace for the Service/EndpointSlice |
| `database_name` | string | Service/EndpointSlice name (must be valid DNS-1123) |
| `database_internal_port` | number | Cluster port (`Service.spec.ports[].port`) |
| `database_host_port` | number | Port on the external database host |
| `database_host` | string | IP or hostname of the external database |

### `host_vars/docker-host.yml`

Per-host vars for the `[docker_host]` group LXC container.

```yaml
---
ansible_user: root
docker_users:
  - root

# Service IP for this host — MANDATORY
# Feeds: K3s datastore endpoint, TLS SAN, k3s server URL, kubeconfig patch
docker_host_ip: 10.27.10.50
```

| Key | Required | Purpose |
|-----|----------|---------|
| `ansible_user` | yes | SSH user for docker-host (default: `root`) |
| `docker_users` | yes | List of users added to `docker` group |
| `docker_host_ip` | **yes** | IP of LXC container. Used by `group_vars/all.yml` to build `k3s_datastore_endpoint`, `k3s_tls_san`, `k3s_server_url`. Missing this breaks playbooks 02 and 02.5. |

### `group_vars/all.yml` (committed defaults)

Do not edit by hand. Override via `vars/local.yml`. Contains all default values for every component.

Key groups:

**Domain:**
- `domain: your.domain` (committed default in `group_vars/all.yml`; override in gitignored `vars/local.yml`. Service domains derive as `<service>.{{ domain }}`.)

**HAProxy:**
- `haproxy_image: haproxy:latest`
- `haproxy_container_name: k3s-haproxy`
- `haproxy_port: 6443`
- `haproxy_memory_limit: 2g`
- `haproxy_config_dir: /usr/local/etc/haproxy`

**MariaDB:**
- `mariadb_image: mariadb:latest`
- `mariadb_container_name: k3s-db`
- `mariadb_database: k3sdb`
- `mariadb_user: k3s`
- `mariadb_password: k3spass`
- `mariadb_root_password: k3spass`
- `mariadb_port: 3306`
- `mariadb_memory_limit: 2g`
- `mariadb_memory_reservation: 1g`
- `mariadb_buffer_pool_size: 1434M`
- `mariadb_data_dir: /var/lib/mysql`

**K3s:**
- `k3s_version: ""` (empty = latest)
- `k3s_disable: [traefik, servicelb, local-storage]`
- `k3s_flannel_backend: host-gw`
- `k3s_dns_upstream: 10.27.10.1`
- `k3s_datastore_endpoint: "mysql://k3s:k3spass@tcp({{ hostvars['docker-host']['docker_host_ip'] }}:3306)/k3sdb"`
- `k3s_tls_san: "{{ hostvars['docker-host']['docker_host_ip'] }}"`
- `k3s_server_url: "https://{{ hostvars['docker-host']['docker_host_ip'] }}:6443"`

**Per-service vars** (namespace, chart, repo_url, release_name, version, domain) for: traefik, metallb, longhorn, prometheus, loki, argocd, fission, eso.

### `group_vars/masters.yml` + `group_vars/workers.yml` (committed)

```yaml
---
ansible_user: "{{ vm_username }}"
ansible_become: yes
```

Both reference `vm_username` from `vars/local.yml`.

### Variable precedence

1. `host_vars/<hostname>.yml` — highest priority (per-host)
2. `vars/local.yml` — loaded via `vars_files` in playbooks (user overrides)
3. `group_vars/all.yml` — committed defaults (lowest priority)

### `ansible/ansible.cfg` (committed)

```ini
[defaults]
host_key_checking = False
inventory = inventory/homelab/hosts.ini
retry_files_enabled = False
stdout_callback = ansible.builtin.default
result_format = yaml
roles_path = roles
deprecation_warnings = False
```

---

## Layer B — Phase 2 services (Terraform)

Base path: `terraform/`

### File layout

```text
terraform/
├── main.tf                      # committed — module wiring
├── variables.tf                 # committed — SINGLE SOURCE OF TRUTH for all vars
├── outputs.tf                   # committed
├── providers.tf                 # committed — uses ~/.kube/config
├── Makefile                     # committed — plan/apply/destroy with -var-file=terraform.tfvars
├── terraform_example.tfvars     # committed — template with placeholder values
├── terraform.tfvars             # gitignored — your personal values + secrets
├── modules/                     # committed — one module per component (9 modules)
└── .terraform/                  # gitignored — terraform init output
```

### Setup

```bash
# 1. Copy example
cp terraform/terraform_example.tfvars terraform/terraform.tfvars

# 2. Edit terraform.tfvars with your values

# 3. Initialize
cd terraform && terraform init

# 4. Plan / Apply / Destroy
make plan
make apply
make destroy
```

Each Makefile target uses `-var-file=terraform.tfvars`.

### `terraform.tfvars` full example

```hcl
# Personal values — DO NOT COMMIT.
# Copy terraform_example.tfvars to this file and customize.

domain = "your.domain"

# Traefik
traefik_namespace        = "traefik"
traefik_chart            = "traefik/traefik"
traefik_repo_url         = "https://traefik.github.io/charts"
traefik_release_name     = "traefik"
traefik_dashboard_user   = "admin"
# traefik_dashboard_domain = "traefik.your.domain"  # optional — defaults to traefik.${var.domain}

# MetalLB
metallb_namespace     = "metallb-system"
metallb_chart         = "metallb/metallb"
metallb_repo_url      = "https://metallb.github.io/metallb"
metallb_release_name  = "metallb"
metallb_ip_pool_range = "10.27.10.60-10.27.10.89"

# Longhorn
longhorn_namespace    = "longhorn-system"
longhorn_chart        = "longhorn/longhorn"
longhorn_repo_url     = "https://charts.longhorn.io"
longhorn_release_name = "longhorn"
longhorn_version      = "1.12.0"
# longhorn_domain       = "longhorn.your.domain"  # optional — defaults to longhorn.${var.domain}
longhornctl_dir       = "/tmp"

# Prometheus
prometheus_namespace    = "monitoring"
prometheus_chart        = "prometheus-community/kube-prometheus-stack"
prometheus_repo_url     = "https://prometheus-community.github.io/helm-charts"
prometheus_release_name = "prometheus"
# prometheus_domain       = "prometheus.your.domain"    # optional — defaults to prometheus.${var.domain}
# alertmanager_domain     = "alertmanager.your.domain"  # optional — defaults to alertmanager.${var.domain}

# Loki
loki_namespace    = "grafana-loki"
loki_chart        = "grafana/loki-stack"
loki_repo_url     = "https://grafana.github.io/helm-charts"
loki_release_name = "loki"
# loki_domain       = "loki.your.domain"  # optional — defaults to loki.${var.domain}

# ArgoCD
argocd_namespace    = "argo-cd"
argocd_chart        = "argo-cd/argo-cd"
argocd_repo_url     = "https://argoproj.github.io/argo-helm"
argocd_release_name = "argo-cd"
# argocd_domain       = "argocd.your.domain"  # optional — defaults to argocd.${var.domain}

# Fission
fission_namespace         = "fission"
fission_chart             = "fission-charts/fission-all"
fission_repo_url          = "https://fission.github.io/fission-charts"
fission_release_name      = "fission"
fission_version           = "1.27.0"
# fission_domain            = "functions.your.domain"  # optional — defaults to functions.${var.domain}
fission_crd_kustomize_url = "https://github.com/fission/fission/crds/v1?ref=v1.27.0"
fission_deploy_examples   = true

# External Secrets Operator — empty = operator-only install (real AWS defaults)
eso_namespace             = "external-secrets"
eso_chart                 = "external-secrets/external-secrets"
eso_repo_url              = "https://charts.external-secrets.io"
eso_release_name          = "external-secrets"
eso_version               = "2.10.0"
eso_install_crds          = true
eso_aws_emulator_endpoint = ""
eso_aws_access_key_id     = ""
eso_aws_secret_access_key = ""
eso_aws_cluster_stores    = []

# External Databases — empty = no Services/EndpointSlices created
external_databases = []

# ── Secrets ──
traefik_dashboard_password = "CHANGE_ME"
```

### Variable reference (55 variables in `variables.tf`)

#### Domain

| Variable | Default | Purpose |
|----------|---------|---------|
| `domain` | `"your.domain"` | Base DNS domain. Service domains default to `<service>.<domain>`. |

#### Traefik (7 variables)

| Variable | Default | Purpose |
|----------|---------|---------|
| `traefik_namespace` | `"traefik"` | Kubernetes namespace |
| `traefik_chart` | `"traefik/traefik"` | Helm chart |
| `traefik_repo_url` | `"https://traefik.github.io/charts"` | Helm repo |
| `traefik_release_name` | `"traefik"` | Helm release name |
| `traefik_dashboard_user` | `"admin"` | Dashboard basic-auth username |
| `traefik_dashboard_password` | `"admin"` | Dashboard basic-auth password — **CHANGE THIS** |
| `traefik_dashboard_domain` | `null` (derived) | Dashboard FQDN. Defaults to `traefik.${var.domain}` via `coalesce` in `main.tf`. Set only to override. |

#### MetalLB (5 variables)

| Variable | Default | Purpose |
|----------|---------|---------|
| `metallb_namespace` | `"metallb-system"` | Kubernetes namespace |
| `metallb_chart` | `"metallb/metallb"` | Helm chart |
| `metallb_repo_url` | `"https://metallb.github.io/metallb"` | Helm repo |
| `metallb_release_name` | `"metallb"` | Helm release name |
| `metallb_ip_pool_range` | `"10.27.10.60-10.27.10.89"` | IP address pool for LoadBalancer Services |

#### Longhorn (7 variables)

| Variable | Default | Purpose |
|----------|---------|---------|
| `longhorn_namespace` | `"longhorn-system"` | Kubernetes namespace |
| `longhorn_chart` | `"longhorn/longhorn"` | Helm chart |
| `longhorn_repo_url` | `"https://charts.longhorn.io"` | Helm repo |
| `longhorn_release_name` | `"longhorn"` | Helm release name |
| `longhorn_version` | `"1.12.0"` | Chart version |
| `longhorn_domain` | `null` (derived) | UI FQDN. Defaults to `longhorn.${var.domain}` via `coalesce` in `main.tf`. Set only to override. |
| `longhornctl_dir` | `"/tmp"` | Directory for longhornctl binary |

#### Prometheus (6 variables)

| Variable | Default | Purpose |
|----------|---------|---------|
| `prometheus_namespace` | `"monitoring"` | Kubernetes namespace |
| `prometheus_chart` | `"prometheus-community/kube-prometheus-stack"` | Helm chart |
| `prometheus_repo_url` | `"https://prometheus-community.github.io/helm-charts"` | Helm repo |
| `prometheus_release_name` | `"prometheus"` | Helm release name |
| `prometheus_domain` | `null` (derived) | Prometheus UI FQDN. Defaults to `prometheus.${var.domain}` via `coalesce` in `main.tf`. Set only to override. |
| `alertmanager_domain` | `null` (derived) | Alertmanager UI FQDN. Defaults to `alertmanager.${var.domain}` via `coalesce` in `main.tf`. Set only to override. |

#### Loki (5 variables)

| Variable | Default | Purpose |
|----------|---------|---------|
| `loki_namespace` | `"grafana-loki"` | Kubernetes namespace |
| `loki_chart` | `"grafana/loki-stack"` | Helm chart |
| `loki_repo_url` | `"https://grafana.github.io/helm-charts"` | Helm repo |
| `loki_release_name` | `"loki"` | Helm release name |
| `loki_domain` | `null` (derived) | Loki FQDN. Defaults to `loki.${var.domain}` via `coalesce` in `main.tf`. Set only to override. |

#### ArgoCD (5 variables)

| Variable | Default | Purpose |
|----------|---------|---------|
| `argocd_namespace` | `"argo-cd"` | Kubernetes namespace |
| `argocd_chart` | `"argo-cd/argo-cd"` | Helm chart |
| `argocd_repo_url` | `"https://argoproj.github.io/argo-helm"` | Helm repo |
| `argocd_release_name` | `"argo-cd"` | Helm release name |
| `argocd_domain` | `null` (derived) | ArgoCD UI FQDN. Defaults to `argocd.${var.domain}` via `coalesce` in `main.tf`. Set only to override. |

#### Fission (8 variables)

| Variable | Default | Purpose |
|----------|---------|---------|
| `fission_namespace` | `"fission"` | Kubernetes namespace |
| `fission_chart` | `"fission-charts/fission-all"` | Helm chart |
| `fission_repo_url` | `"https://fission.github.io/fission-charts"` | Helm repo |
| `fission_release_name` | `"fission"` | Helm release name |
| `fission_version` | `"1.27.0"` | Chart version |
| `fission_domain` | `null` (derived) | Functions FQDN. Defaults to `functions.${var.domain}` via `coalesce` in `main.tf`. Set only to override. |
| `fission_crd_kustomize_url` | `"https://github.com/fission/fission/crds/v1?ref=v1.27.0"` | CRD kustomize URL (applied via local-exec) |
| `fission_deploy_examples` | `true` | Deploy example functions |

#### External Secrets Operator (10 variables)

| Variable | Default | Purpose |
|----------|---------|---------|
| `eso_namespace` | `"external-secrets"` | Kubernetes namespace |
| `eso_chart` | `"external-secrets/external-secrets"` | Helm chart |
| `eso_repo_url` | `"https://charts.external-secrets.io"` | Helm repo |
| `eso_release_name` | `"external-secrets"` | Helm release name |
| `eso_version` | `"2.10.0"` | Chart version |
| `eso_install_crds` | `true` | Install ESO CRDs |
| `eso_aws_emulator_endpoint` | `""` | Emulator endpoint URL. Empty = real AWS defaults. Non-empty = emulator mode. |
| `eso_aws_access_key_id` | `""` | AWS access key (emulator mode) |
| `eso_aws_secret_access_key` | `""` | AWS secret key (emulator mode) |
| `eso_aws_cluster_stores` | `[]` | List of ClusterSecretStore objects. Empty = operator-only install. |

#### External Databases (1 variable)

| Variable | Default | Purpose |
|----------|---------|---------|
| `external_databases` | `[]` | List of external DBs to expose as in-cluster Services/EndpointSlices. Empty = no resources created. |

### HCL examples

#### `eso_aws_cluster_stores`

```hcl
eso_aws_cluster_stores = [
  {
    name    = "eso-aws"
    region  = "us-east-1"
    service = "SecretsManager"
  },
  {
    name    = "eso-aws-eu"
    region  = "eu-west-1"
    service = "SecretsManager"
  }
]
```

#### `external_databases`

```hcl
external_databases = [
  {
    namespace              = "databases"
    database_name          = "mysql"
    database_internal_port = 3306
    database_host_port     = 3306
    database_host          = "10.27.10.37"
  },
  {
    namespace              = "databases"
    database_name          = "postgresql"
    database_internal_port = 5432
    database_host_port     = 5432
    database_host          = "10.27.10.37"
  }
]
```

---

## Secrets & gitignore

### Gitignored files (never committed)

| File | Contains |
|------|----------|
| `ansible/inventory/homelab/hosts.ini` | Host IPs |
| `ansible/inventory/homelab/vars/local.yml` | `vm_username`, `ansible_become_password`, `eso_aws_credentials`, `external_databases` |
| `ansible/inventory/homelab/host_vars/docker-host.yml` | `docker_host_ip`, `ansible_user` |
| `terraform/terraform.tfvars` | All personal values + secrets (`traefik_dashboard_password`, `eso_aws_*`) |
| `terraform/*.tfstate*` | Terraform state |
| `terraform/.terraform/` | Provider plugins |

### Committed files (safe to share)

| File | Contains |
|------|----------|
| `ansible/inventory/homelab/hosts.ini.example` | Template |
| `ansible/inventory/homelab/vars/local.yml.example` | Template with comments |
| `ansible/inventory/homelab/host_vars/docker-host.yml.example` | Template |
| `terraform/terraform_example.tfvars` | Template with placeholder values |
| `terraform/variables.tf` | Variable declarations + defaults (single source of truth) |
| `ansible/inventory/homelab/group_vars/all.yml` | Default values for all components |
| `ansible/inventory/homelab/group_vars/masters.yml` | `ansible_user` + `ansible_become` |
| `ansible/inventory/homelab/group_vars/workers.yml` | `ansible_user` + `ansible_become` |

### Secret placement

- **Ansible secrets** (`ansible_become_password`, `eso_aws_credentials`) → `vars/local.yml`
- **Terraform secrets** (`traefik_dashboard_password`, `eso_aws_access_key_id`, `eso_aws_secret_access_key`) → `terraform.tfvars`
- `secrets.tfvars` is no longer used. All secrets live in `terraform.tfvars`.

---

## Gotchas & troubleshooting

### `docker_host_ip` missing

Symptom: Playbooks 02 and 02.5 fail. The `k3s_datastore_endpoint`, `k3s_tls_san`, and `k3s_server_url` all interpolate `hostvars['docker-host']['docker_host_ip']`. If unset, K3s cannot connect to MariaDB and TLS SAN is wrong.

Fix: Set `docker_host_ip` in `host_vars/docker-host.yml`.

### `vm_username` missing

Symptom: Ansible cannot SSH to masters/workers. `group_vars/masters.yml` and `group_vars/workers.yml` set `ansible_user: "{{ vm_username }}"`.

Fix: Set `vm_username` in `vars/local.yml`.

### `eso_aws_emulator.endpoint` empty string

Symptom: Playbook 11 fails with explicit error. Empty string is not the same as absent.

Fix: Either remove the `endpoint` key entirely (real AWS mode) or set a reachable URL (emulator mode).

### Emulator endpoint not reachable from cluster

Symptom: ESO controller cannot reach the emulator. The endpoint must be reachable **from inside the cluster**, not from the control node. `localhost` or `127.0.0.1` will not work.

Fix: Use the host's LAN IP (e.g. `http://10.27.10.38:4566`).

### Empty `eso_aws_cluster_stores`

Behavior: Operator-only install. No `ClusterSecretStore` resources created. No AWS provider connection.

### Empty `external_databases`

Behavior: No Services or EndpointSlices created for external databases.

### Terraform kubeconfig

Terraform `providers.tf` uses `~/.kube/config` for helm and kubernetes providers. Phase 1 step 2.5 (`02.5-kubeconfig.yml`) fetches kubeconfig to this location. If skipped, ensure kubeconfig is present before `make plan`.

### MetalLB IP pool mismatch

If `metallb_ip_pool_range` differs between Layer A (`vars/local.yml`) and Layer B (`terraform.tfvars`), services will get IPs outside the expected range. Keep them in sync.

### Domain mismatch

If `domain` differs between layers, service FQDNs will not match. Keep `domain` consistent or override each `*_domain` variable explicitly.

---

## Where defaults live

| Layer | File | Role |
|-------|------|------|
| A | `ansible/inventory/homelab/group_vars/all.yml` | Committed defaults for all Ansible vars |
| A | `ansible/inventory/homelab/vars/local.yml.example` | Template for user overrides |
| A | `ansible/inventory/homelab/host_vars/docker-host.yml.example` | Template for docker-host vars |
| B | `terraform/variables.tf` | Single source of truth for all Terraform vars (55 variables) |
| B | `terraform/terraform_example.tfvars` | Template for user values |

Both layers mirror the same service configuration (namespace, chart, repo, release name, version, domain). Layer A uses YAML; Layer B uses HCL. Defaults match across both.
