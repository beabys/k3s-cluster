# k3s-cluster — Agent Guide

## Repo purpose
Helm values + K8s manifests for bootstrapping a K3s cluster with external HAProxy + MariaDB datastore.

## Branch state
`main` is stale (initial commit). Real work is on separate branches:
- `update/update_instructions` — latest changes
- `deploy_argo_using_traefik` — ArgoCD deployment fix
- `first_instructions_and_yamls` — initial full structure

**Before working, check if `main` needs a merge or rebase from these branches.**

## Installation order (required)
1. traefik
2. metallb
3. longhorn (prereqs: iSCSI + NFSv4)
4. prometheus
5. loki
6. argocd
7. keycloak

## Structure
Each service dir contains a `values.yaml` (Helm) + `Readme.md` with install commands. Manifests in `*.yml`/`*.yaml` alongside.

### Key files
| Dir | Purpose |
|-----|---------|
| `traefik/` | Ingress controller (values + dashboard CRD) |
| `metallb/` | LoadBalancer IP pool `10.27.10.60-89` |
| `longhorn/` | Distributed storage (value.yaml — typo intentional) |
| `prometheus-helm/` | kube-prometheus-stack, 3 ingress YAMLs |
| `loki-helm/` | Loki stack + Promtail |
| `argocd/` | ArgoCD GitOps |
| `keycloak/` | Single YAML (Ingress + Service + Deployment) |
| `consul/` | HashiCorp Consul service mesh |

## Conventions
- All ingress: `*.home.lab`, `ingressClassName: traefik`
- Longhorn is default StorageClass for stateful workloads
- `values_loki.yaml` in `prometheus-helm/` is a duplicate of `loki-helm/values.yaml`
- `longhorn/value.yaml` naming typo is intentional (matches existing file)
- No CI, Makefile, or shell scripts — all deploy is manual `helm`/`kubectl`
- No linter/formatter configs exist
- No `.gitignore` exists

## Gotchas
- **Flannel VXLAN broken on Ubuntu 26.04 (kernel 7.0.0)** — pods on some nodes can't reach others. Fix: set `flannel-backend: host-gw` in `/etc/rancher/k3s/config.yaml` on server nodes. All nodes are on same L2 subnet so no encapsulation needed.
- keycloak passwords in plaintext (`KEYCLOAK_ADMIN_PASSWORD: "admin"`)
- `consul/values_ex.yaml` is the full upstream reference (1067+ lines, not the active values)
- `consul/helm-consul-values.yaml` is a 1-replica variant (main values.yaml uses 3)
- `traefik/traefik-dashbord-crd.yml` (typo in filename) creates basic-auth IngressRoute
