# Installing Traefik

## Install

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik -n traefik --create-namespace
```

## Dashboard

### Option A — Helm values (recommended)

Enable dashboard and basic auth in `values.yaml`, then upgrade:

```bash
helm upgrade traefik traefik/traefik -n traefik -f values.yaml
```

### Option B — Manual CRD

Create the basic auth secret, then apply the CRD:

```bash
# Create auth credentials (replace admin/admin)
# Or generate with: htpasswd -c traefik-auth admin
htpasswd -nb admin admin | kubectl -n traefik create secret generic traefik-dashboard-auth --from-file=users=/dev/stdin

# Apply the IngressRoute + Middleware
kubectl apply -f traefik-dashbord-crd.yml
```

### Access

`http://traefik.home.lab/dashboard/` (basic auth with the credentials you set).

Requires DNS (or `/etc/hosts`) resolving `traefik.home.lab` to your MetalLB IP pool range.
