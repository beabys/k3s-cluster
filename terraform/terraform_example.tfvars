# Copy this file to terraform.tfvars and customize for your environment.
# terraform.tfvars is gitignored — your personal values stay local.
# Secrets (traefik_dashboard_password, eso_aws_*) go in secrets.tfvars (also gitignored).

domain = "example.com"

# Traefik
traefik_namespace        = "traefik"
traefik_chart            = "traefik/traefik"
traefik_repo_url         = "https://traefik.github.io/charts"
traefik_release_name     = "traefik"
traefik_dashboard_user   = "admin"
traefik_dashboard_domain = "traefik.example.com"

# MetalLB
metallb_namespace     = "metallb-system"
metallb_chart         = "metallb/metallb"
metallb_repo_url      = "https://metallb.github.io/metallb"
metallb_release_name  = "metallb"
metallb_ip_pool_range = "10.0.0.60-10.0.0.89"

# Longhorn
longhorn_namespace    = "longhorn-system"
longhorn_chart        = "longhorn/longhorn"
longhorn_repo_url     = "https://charts.longhorn.io"
longhorn_release_name = "longhorn"
longhorn_version      = "1.12.0"
longhorn_domain       = "longhorn.example.com"
longhornctl_dir       = "/tmp"

# Prometheus
prometheus_namespace    = "monitoring"
prometheus_chart        = "prometheus-community/kube-prometheus-stack"
prometheus_repo_url     = "https://prometheus-community.github.io/helm-charts"
prometheus_release_name = "prometheus"
prometheus_domain       = "prometheus.example.com"
alertmanager_domain     = "alertmanager.example.com"

# Loki
loki_namespace    = "grafana-loki"
loki_chart        = "grafana/loki-stack"
loki_repo_url     = "https://grafana.github.io/helm-charts"
loki_release_name = "loki"
loki_domain       = "loki.example.com"

# ArgoCD
argocd_namespace    = "argo-cd"
argocd_chart        = "argo-cd/argo-cd"
argocd_repo_url     = "https://argoproj.github.io/argo-helm"
argocd_release_name = "argo-cd"
argocd_domain       = "argocd.example.com"

# Fission
fission_namespace            = "fission"
fission_chart                = "fission-charts/fission-all"
fission_repo_url             = "https://fission.github.io/fission-charts"
fission_release_name         = "fission"
fission_version              = "1.27.0"
fission_domain               = "functions.example.com"
fission_crd_kustomize_url    = "https://github.com/fission/fission/crds/v1?ref=v1.27.0"
fission_deploy_examples      = true

# External Secrets Operator — empty = operator-only install (real AWS defaults)
eso_namespace            = "external-secrets"
eso_chart                = "external-secrets/external-secrets"
eso_repo_url             = "https://charts.external-secrets.io"
eso_release_name         = "external-secrets"
eso_version              = "2.10.0"
eso_install_crds         = true
eso_aws_emulator_endpoint = ""
eso_aws_access_key_id    = ""
eso_aws_secret_access_key = ""
eso_aws_cluster_stores   = []

# External Databases — empty = no Services/EndpointSlices created
external_databases = []

# ── Secrets ──
traefik_dashboard_password = "CHANGE_ME"