# Plan: Ansible Migration — Step 02.5: Fetch Kubeconfig

## Request
After K3s is installed (Step 02) and before any Helm deployments (Steps 03-08), fetch the kubeconfig from the first master, patch the server address to point to the HAProxy load balancer (`10.27.10.50:6443`), and save it to `~/.kube/config` on the control node.

This is a **critical missing dependency** — all localhost playbooks (Traefik, MetalLB, Longhorn, Prometheus, Loki, ArgoCD) require `~/.kube/config` to communicate with the K3s cluster.

## Problem

After Step 02:
- K3s is running on masters
- kubeconfig exists at `/etc/rancher/k3s/k3s.yaml` on master1 with `server: https://127.0.0.1:6443`
- Control node (your Mac) has NO kubeconfig → `kubectl` and `helm` commands fail
- The server address must point to the HAProxy IP (`10.27.10.50:6443`) so traffic goes through the load balancer

## Solution

Add a new playbook `02.5-kubeconfig.yml` that:
1. **Reads** `/etc/rancher/k3s/k3s.yaml` from master1 via SSH
2. **Patches** the `server:` field from `127.0.0.1`/`localhost` to `{{ docker_host_ip }}:6443`
3. **Updates** the `current-context` or creates a merged config
4. **Saves** to `~/.kube/config` on the control node
5. **Sets** `KUBECONFIG` env or validates with `kubectl get nodes`

## Files Changed

| Path | Action | Reason |
|------|--------|--------|
| `ansible/playbooks/02.5-kubeconfig.yml` | CREATE | Fetch, patch, save kubeconfig |
| `ansible/test.sh` | MODIFY | Add 02.5 syntax check |
| `ansible/inventory/homelab/group_vars/all.yml` | MODIFY (optional) | Add `kubeconfig_path` var |

## Implementation

### Playbook structure (single play, SSH to master1)

```yaml
- name: Fetch and configure kubeconfig
  hosts: masters[0]
  gather_facts: no
  tasks:
    - name: Read k3s.yaml from master
      slurp:
        src: /etc/rancher/k3s/k3s.yaml
      register: kubeconfig_raw
    
    - name: Patch server address to HAProxy
      set_fact:
        kubeconfig_content: "{{ kubeconfig_raw.content | b64decode | regex_replace('server: https://127.0.0.1:6443', 'server: https://' ~ docker_host_ip ~ ':6443') }}"
    
    - name: Ensure ~/.kube directory exists on control node
      file:
        path: "~/.kube"
        state: directory
        mode: "0755"
      delegate_to: localhost
    
    - name: Write kubeconfig to control node
      copy:
        content: "{{ kubeconfig_content }}"
        dest: "~/.kube/config"
        mode: "0600"
      delegate_to: localhost
    
    - name: Backup existing kubeconfig if present
      copy:
        src: "~/.kube/config"
        dest: "~/.kube/config.backup"
        remote_src: no
      delegate_to: localhost
      failed_when: false   # ignore if no existing config
```

### Alternative approach (simpler, using fetch module)
```yaml
    - name: Fetch k3s.yaml from master
      fetch:
        src: /etc/rancher/k3s/k3s.yaml
        dest: /tmp/k3s.yaml
        flat: yes
      delegate_to: localhost
    
    - name: Patch server address
      replace:
        path: /tmp/k3s.yaml
        regexp: 'server: https://127.0.0.1:6443'
        replace: 'server: https://{{ docker_host_ip }}:6443'
      delegate_to: localhost
    
    - name: Copy to ~/.kube/config
      copy:
        src: /tmp/k3s.yaml
        dest: "{{ lookup('env', 'HOME') }}/.kube/config"
        mode: "0600"
      delegate_to: localhost
```

**Recommendation:** Use the `fetch` + `replace` approach (cleaner, uses file-based operations).

## Placement

Run immediately after Step 02, before any Step 03-08 playbooks:

```bash
ansible-playbook playbooks/02-k3s.yml           # Install K3s
ansible-playbook playbooks/02.5-kubeconfig.yml   # Fetch kubeconfig ← NEW
ansible-playbook playbooks/03-traefik.yml        # Now can talk to cluster
```

## Testing (Static Only)
- `ansible-lint .`
- `--syntax-check playbooks/02.5-kubeconfig.yml`
- `./test.sh`

## Risks / Open Questions

1. **Server address format** — The k3s.yaml may have `https://localhost:6443` or `https://127.0.0.1:6443`. Should handle both.
2. **Existing kubeconfig** — User may already have a kubeconfig from other clusters. The `fetch` module approach overwrites `~/.kube/config`. Should backup first.
3. **Context name** — k3s.yaml uses a default context. Works for single cluster. No need to rename.
4. **`~` expansion** — Ansible's `lookup('env', 'HOME')` or `ansible_env.HOME` resolves the home directory correctly.

## Progress

- [x] 2026-06-27 — Dev done: 2 files, lint + syntax pass
- [x] 2026-06-27 — Reviewer: REJECTED — `ansible_env` bug (gather_facts:false)
- [x] 2026-06-27 — Dev fix: replaced with `lookup('env', 'HOME')`
- [x] 2026-06-27 — Reviewer re-review: APPROVED
- [x] 2026-06-27 — QA: PASSED — 10/10 test.sh
- [x] 2026-06-27 — Final report delivered
