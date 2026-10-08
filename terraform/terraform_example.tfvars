# Copy this file to terraform.tfvars and customize for your environment.
# terraform.tfvars is gitignored — your personal values stay local.
# Secrets (traefik_dashboard_password, eso_aws_*) go in terraform.tfvars (gitignored).

domain = "example.com"

# Traefik
traefik_namespace      = "traefik"
traefik_chart          = "traefik"
traefik_repo_url       = "https://traefik.github.io/charts"
traefik_version        = "41.6.1"
traefik_release_name   = "traefik"
traefik_dashboard_user = "admin"
# OPTIONAL: defaults to traefik.<domain> if unset
traefik_dashboard_domain = "traefik.example.com"

# MetalLB
metallb_namespace     = "metallb-system"
metallb_chart         = "metallb"
metallb_repo_url      = "https://metallb.github.io/metallb"
metallb_version       = "0.16.1"
metallb_release_name  = "metallb"
metallb_ip_pool_range = "10.0.0.60-10.0.0.89"

# Longhorn
longhorn_namespace    = "longhorn-system"
longhorn_chart        = "longhorn"
longhorn_repo_url     = "https://charts.longhorn.io"
longhorn_release_name = "longhorn"
longhorn_version      = "1.12.0"
# OPTIONAL: defaults to longhorn.<domain> if unset
longhorn_domain = "longhorn.example.com"
longhornctl_dir = "/tmp"

# Prometheus
prometheus_namespace    = "monitoring"
prometheus_chart        = "kube-prometheus-stack"
prometheus_repo_url     = "https://prometheus-community.github.io/helm-charts"
prometheus_version      = "91.9.0"
prometheus_release_name = "prometheus"
# OPTIONAL: defaults to prometheus.<domain> if unset
prometheus_domain = "prometheus.example.com"
# OPTIONAL: defaults to alertmanager.<domain> if unset
alertmanager_domain = "alertmanager.example.com"

# Elasticsearch
elasticsearch_namespace    = "elasticsearch"
elasticsearch_chart        = "elasticsearch"
elasticsearch_repo_url     = "https://helm.elastic.co"
elasticsearch_release_name = "elasticsearch"
elasticsearch_version      = "8.5.1"
elasticsearch_storage_size = "10Gi"

# Jaeger
jaeger_namespace    = "jaeger"
jaeger_chart        = "jaeger"
jaeger_repo_url     = "https://jaegertracing.github.io/helm-charts"
jaeger_release_name = "jaeger"
jaeger_version      = "4.14.1"
# OPTIONAL: defaults to jaeger.<domain> if unset
jaeger_domain = "jaeger.example.com"

# OpenTelemetry Collector
otel_namespace    = "observability"
otel_chart        = "opentelemetry-collector"
otel_repo_url     = "https://open-telemetry.github.io/opentelemetry-helm-charts"
otel_release_name = "otel-collector"
otel_version      = "0.175.1"

# Grafana
grafana_namespace    = "monitoring"
grafana_chart        = "grafana"
grafana_repo_url     = "https://grafana.github.io/helm-charts"
grafana_release_name = "grafana"
grafana_version      = "10.5.15"
# OPTIONAL: defaults to grafana.<domain> if unset
grafana_domain         = "grafana.example.com"
grafana_admin_password = "CHANGE_ME"

# ArgoCD
argocd_namespace    = "argo-cd"
argocd_chart        = "argo-cd"
argocd_repo_url     = "https://argoproj.github.io/argo-helm"
argocd_version      = "10.9.6"
argocd_release_name = "argo-cd"
# OPTIONAL: defaults to argocd.<domain> if unset
argocd_domain = "argocd.example.com"

# Fission
fission_namespace    = "fission"
fission_chart        = "fission-all"
fission_repo_url     = "https://fission.github.io/fission-charts"
fission_release_name = "fission"
fission_version      = "1.27.0"
# OPTIONAL: defaults to functions.<domain> if unset
fission_domain            = "functions.example.com"
fission_crd_kustomize_url = "https://github.com/fission/fission/crds/v1?ref=v1.27.0"
fission_deploy_examples   = true

# External Secrets Operator — empty = operator-only install (real AWS defaults)
eso_namespace             = "external-secrets"
eso_chart                 = "external-secrets"
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

# Registry pull secrets — per-namespace dockerconfigjson image-pull secrets.
# Replaces node-level k3s registries.yaml auth. Empty = no secrets created.
# registry_secrets = [
#   {
#     secret_name = "registry-name"
#     server      = "registry.example.com"
#     username    = "user"
#     password    = "CHANGE_ME"
#     namespaces  = ["ns-one", "ns-two"]
#   }
# ]
registry_secrets           = []
registry_manage_namespaces = true

# CRD bootstrap gate — two-pass apply:
# Pass 1: enable_crd_manifests=false (installs Helm charts, creates CRDs)
# Pass 2: enable_crd_manifests=true (applies CRD-dependent manifests)
enable_crd_manifests = false

# ── Secrets ──
traefik_dashboard_password = "CHANGE_ME"