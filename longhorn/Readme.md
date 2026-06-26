# Installing Longhorn v1.12.0

## Prerequisites

### 1. Install prerequisites on all nodes

Longhorn needs `open-iscsi` and `nfs-common` on each node.
The recommended way (kubectl-only, no SSH needed) is to use the Longhorn CLI tool.
It talks to the cluster API via your kubeconfig and deploys a temporary pod on
each node that runs the package manager (apt/yum/zypper) inside the host
namespace — same mechanism as the old v1.7 DaemonSet YAMLs:

```bash
# Detect OS and arch, download matching longhornctl binary
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ARCH="amd64" ;;
  aarch64) ARCH="arm64" ;;
esac
curl -sSfL -o longhornctl \
  "https://github.com/longhorn/cli/releases/download/v1.12.0/longhornctl-${OS}-${ARCH}"
chmod +x longhornctl

# Create namespace (preflight installer deploys pods into longhorn-system)
kubectl create namespace longhorn-system

# Install prerequisites on all nodes (deploys DaemonSet via your kubeconfig)
./longhornctl --kubeconfig ~/.kube/config --image longhornio/longhorn-cli:v1.12.0 install preflight

# Verify installation
./longhornctl --kubeconfig ~/.kube/config check preflight
```

Check installation result (`iscsi install successfully` / `nfs install successfully` expected).

> If you prefer OS package manager commands, install on each node:
> - **Debian/Ubuntu:** `apt-get install open-iscsi nfs-common`
> - **RHEL/CentOS:** `yum install iscsi-initiator-utils nfs-utils`
> - **SUSE:** `zypper install open-iscsi nfs-client`

## 2. Install Longhorn

### Option A — Helm (recommended for customization)

```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn longhorn/longhorn -f value.yaml --namespace longhorn-system --create-namespace --version 1.12.0
```

### Option B — kubectl (no Helm needed)

```bash
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.12.0/deploy/longhorn.yaml
```

### Verify installation

```bash
kubectl -n longhorn-system get pod --watch
```

Expect pods: longhorn-ui, longhorn-manager, longhorn-csi-plugin, instance-manager, engine-image.

## 3. Access the UI

An Ingress controller is required for external access.
The file `longhorn-ingress-controller.yml` in this directory creates a Traefik IngressRoute for `longhorn.home.lab`.

## Uninstalling Longhorn

```bash
# Allow deletion
kubectl -n longhorn-system patch -p '{"value": "true"}' --type=merge lhs deleting-confirmation-flag

# Uninstall helm release
helm uninstall longhorn -n longhorn-system

# Clean up namespace
kubectl delete namespace longhorn-system
```

## Notes
- K3s CSI path: `/var/lib/kubelet` (configured in `value.yaml`)
- Default storage type: filesystem (configured in `value.yaml`)
- Backup features require NFSv4 client installed (done in prerequisites step)
- RWX volumes require NFSv4.1 client

## Troubleshooting

### Flannel VXLAN broken on Ubuntu 26.04 (kernel 7.0.0)

If Longhorn pods stay stuck (`Init:0/1`, `CrashLoopBackOff`) and cannot
reach each other across nodes, the default Flannel VXLAN backend may not
work on newer kernels. Symptom: `curl` to ClusterIPs or pod IPs on other
nodes times out, even though routes and VXLAN FDB look correct.

**Fix** — Switch Flannel from VXLAN to `host-gw` on the server nodes.
Since all nodes are on the same L2 subnet (`10.27.10.0/24`), no
encapsulation is needed.

On each **server** (control-plane) node, create/edit
`/etc/rancher/k3s/config.yaml`:

```yaml
flannel-backend: host-gw
```

Then restart K3s on all nodes:

```bash
# On server nodes:
sudo systemctl restart k3s

# On worker nodes:
sudo systemctl restart k3s-agent
```

After restart, verify cross-node pod connectivity:

```bash
kubectl -n longhorn-system exec <pod-name> -c longhorn-manager -- ping -c 2 <other-pod-ip>
```

If you see replies, the fix worked. All Longhorn pods should start
within a few minutes.
