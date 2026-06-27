# k3s-cluster

Ansible-based bootstrapping for a K3s cluster with external HAProxy + MariaDB datastore.

## Prerequisites

- **Control node:** Your Mac (or CI/CD runner) with:
  - `ansible-core >= 2.15`
  - `ansible-galaxy collection install community.docker kubernetes.core`
  - `helm` + `kubectl` installed, `~/.kube/config` pointing to K3s cluster
- **LXC container** (10.27.10.50) running Ubuntu, SSH root access
- **VM nodes** (10.27.10.51-54) running Ubuntu, SSH user with passwordless sudo

## Setup

```bash
cd ansible

# Create local config
cp inventory/homelab/vars/local.yml.example inventory/homelab/vars/local.yml
# Edit local.yml: set vm_username and ansible_become_password
```

## Deployment Order

Run these in sequence. Steps 1-2 use SSH, steps 3-8 run via kubeconfig (localhost).

| Step | Playbook | What | Auth |
|------|----------|------|------|
| 1 | `playbooks/01-infra.yml` | HAProxy + MariaDB (Docker on LXC) | root SSH |
| 2 | `playbooks/02-k3s.yml` | K3s on masters + workers | SSH + sudo |
| 2.5 | `playbooks/02.5-kubeconfig.yml` | Fetch kubeconfig to control node | SSH + sudo |
| 3 | `playbooks/03-traefik.yml` | Traefik ingress controller | localhost/kubeconfig |
| 4 | `playbooks/04-metallb.yml` | MetalLB load balancer | localhost/kubeconfig |
| 5 | `playbooks/05-longhorn.yml` | Longhorn distributed storage | localhost/kubeconfig |
| 6 | `playbooks/06-prometheus.yml` | Prometheus monitoring | localhost/kubeconfig |
| 7 | `playbooks/07-loki.yml` | Loki log aggregation | localhost/kubeconfig |
| 8 | `playbooks/08-argocd.yml` | ArgoCD GitOps | localhost/kubeconfig |

### Run commands

```bash
cd ansible

ansible-playbook playbooks/01-infra.yml
ansible-playbook playbooks/02-k3s.yml              # add --ask-become-pass if no local.yml
ansible-playbook playbooks/02.5-kubeconfig.yml      # fetch kubeconfig
ansible-playbook playbooks/03-traefik.yml
ansible-playbook playbooks/04-metallb.yml
ansible-playbook playbooks/05-longhorn.yml
ansible-playbook playbooks/06-prometheus.yml
ansible-playbook playbooks/07-loki.yml
ansible-playbook playbooks/08-argocd.yml
```

## Services

| Service | Domain | Namespace |
|---------|--------|-----------|
| Traefik Dashboard | `traefik.home.lab` | `traefik` |
| Longhorn UI | `longhorn.home.lab` | `longhorn-system` |
| Prometheus | `prometheus.home.lab` | `monitoring` |
| Alertmanager | `alertmanager.home.lab` | `monitoring` |
| Loki | `loki.home.lab` | `grafana-loki` |
| ArgoCD | `argocd.home.lab` | `argo-cd` |

## Legacy

Original manual installation guides (Helm commands, `kubectl apply`, etc.) are preserved in [`legacy/`](legacy/).
