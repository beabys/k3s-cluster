# Central variable file — single source of truth for all components.
# Mirrors ansible/inventory/group_vars/all.yml + local.yml merged into one file.

# Domain
variable "domain" {
  description = "Base DNS domain for all services"
  default     = "your.domain"
}

# Traefik
variable "traefik_namespace" {
  default = "traefik"
}
variable "traefik_chart" {
  default = "traefik"
}
variable "traefik_repo_url" {
  default = "https://traefik.github.io/charts"
}
variable "traefik_version" {
  default = "41.6.1"
}
variable "traefik_release_name" {
  default = "traefik"
}
variable "traefik_dashboard_user" {
  default = "admin"
}
variable "traefik_dashboard_password" {
  default = "admin"
}
variable "traefik_dashboard_domain" {
  default = null
}

# MetalLB
variable "metallb_namespace" {
  default = "metallb-system"
}
variable "metallb_chart" {
  default = "metallb"
}
variable "metallb_repo_url" {
  default = "https://metallb.github.io/metallb"
}
variable "metallb_version" {
  default = "0.16.1"
}
variable "metallb_release_name" {
  default = "metallb"
}
variable "metallb_ip_pool_range" {
  default = "10.27.10.60-10.27.10.89"
}

# Longhorn
variable "longhorn_namespace" {
  default = "longhorn-system"
}
variable "longhorn_chart" {
  default = "longhorn"
}
variable "longhorn_repo_url" {
  default = "https://charts.longhorn.io"
}
variable "longhorn_release_name" {
  default = "longhorn"
}
variable "longhorn_version" {
  default = "1.12.0"
}
variable "longhorn_domain" {
  default = null
}
variable "longhornctl_dir" {
  default = "/tmp"
}

# Prometheus
variable "prometheus_namespace" {
  default = "monitoring"
}
variable "prometheus_chart" {
  default = "kube-prometheus-stack"
}
variable "prometheus_repo_url" {
  default = "https://prometheus-community.github.io/helm-charts"
}
variable "prometheus_version" {
  default = "91.9.0"
}
variable "prometheus_release_name" {
  default = "prometheus"
}
variable "prometheus_domain" {
  default = null
}
variable "alertmanager_domain" {
  default = null
}

# Elasticsearch
variable "elasticsearch_namespace" {
  default = "elasticsearch"
}
variable "elasticsearch_chart" {
  default = "elasticsearch"
}
variable "elasticsearch_repo_url" {
  default = "https://helm.elastic.co"
}
variable "elasticsearch_release_name" {
  default = "elasticsearch"
}
variable "elasticsearch_version" {
  default = "8.5.1"
}
variable "elasticsearch_storage_size" {
  default = "10Gi"
}

# Jaeger
variable "jaeger_namespace" {
  default = "jaeger"
}
variable "jaeger_chart" {
  default = "jaeger"
}
variable "jaeger_repo_url" {
  default = "https://jaegertracing.github.io/helm-charts"
}
variable "jaeger_release_name" {
  default = "jaeger"
}
variable "jaeger_version" {
  default = "4.14.1"
}
variable "jaeger_domain" {
  default = null
}

# OpenTelemetry Collector
variable "otel_namespace" {
  default = "observability"
}
variable "otel_chart" {
  default = "opentelemetry-collector"
}
variable "otel_repo_url" {
  default = "https://open-telemetry.github.io/opentelemetry-helm-charts"
}
variable "otel_release_name" {
  default = "otel-collector"
}
variable "otel_version" {
  default = "0.175.1"
}

# Grafana
variable "grafana_namespace" {
  default = "monitoring"
}
variable "grafana_chart" {
  default = "grafana"
}
variable "grafana_repo_url" {
  default = "https://grafana.github.io/helm-charts"
}
variable "grafana_release_name" {
  default = "grafana"
}
variable "grafana_version" {
  default = "10.5.15"
}
variable "grafana_domain" {
  default = null
}
variable "grafana_admin_password" {
  default = "admin"
}

# ArgoCD
variable "argocd_namespace" {
  default = "argo-cd"
}
variable "argocd_chart" {
  default = "argo-cd"
}
variable "argocd_repo_url" {
  default = "https://argoproj.github.io/argo-helm"
}
variable "argocd_version" {
  default = "10.9.6"
}
variable "argocd_release_name" {
  default = "argo-cd"
}
variable "argocd_domain" {
  default = null
}

# Fission
variable "fission_namespace" {
  default = "fission"
}
variable "fission_chart" {
  default = "fission-all"
}
variable "fission_repo_url" {
  default = "https://fission.github.io/fission-charts"
}
variable "fission_release_name" {
  default = "fission"
}
variable "fission_version" {
  default = "1.27.0"
}
variable "fission_domain" {
  default = null
}
variable "fission_crd_kustomize_url" {
  default = "https://github.com/fission/fission/crds/v1?ref=v1.27.0"
}
variable "fission_deploy_examples" {
  default = true
}

# External Secrets Operator
variable "eso_namespace" {
  default = "external-secrets"
}
variable "eso_chart" {
  default = "external-secrets"
}
variable "eso_repo_url" {
  default = "https://charts.external-secrets.io"
}
variable "eso_release_name" {
  default = "external-secrets"
}
variable "eso_version" {
  default = "2.10.0"
}
variable "eso_install_crds" {
  default = true
}
variable "eso_aws_emulator_endpoint" {
  default = ""
}
variable "eso_aws_access_key_id" {
  default = ""
}
variable "eso_aws_secret_access_key" {
  default = ""
}
variable "eso_aws_cluster_stores" {
  type = list(object({
    name    = string
    region  = string
    service = string
  }))
  default = []
}

# External Databases
variable "external_databases" {
  type = list(object({
    namespace              = string
    database_name          = string
    database_internal_port = number
    database_host_port     = number
    database_host          = string
  }))
  default = []
}

# CRD bootstrap gate — run first apply with false, then true after Helm installs CRDs
variable "enable_crd_manifests" {
  description = "Gate CRD-dependent manifests; run first apply with false, then true."
  type        = bool
  default     = false
}