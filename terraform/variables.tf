# Central variable file — single source of truth for all components.
# Mirrors ansible/inventory/group_vars/all.yml + local.yml merged into one file.

# Domain
variable "domain" {
  description = "Base DNS domain for all services"
  default     = "home.beabys.com"
}

# Traefik
variable "traefik_namespace" {
  default = "traefik"
}
variable "traefik_chart" {
  default = "traefik/traefik"
}
variable "traefik_repo_url" {
  default = "https://traefik.github.io/charts"
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
  default = "traefik.home.beabys.com"
}

# MetalLB
variable "metallb_namespace" {
  default = "metallb-system"
}
variable "metallb_chart" {
  default = "metallb/metallb"
}
variable "metallb_repo_url" {
  default = "https://metallb.github.io/metallb"
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
  default = "longhorn/longhorn"
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
  default = "longhorn.home.beabys.com"
}
variable "longhornctl_dir" {
  default = "/tmp"
}

# Prometheus
variable "prometheus_namespace" {
  default = "monitoring"
}
variable "prometheus_chart" {
  default = "prometheus-community/kube-prometheus-stack"
}
variable "prometheus_repo_url" {
  default = "https://prometheus-community.github.io/helm-charts"
}
variable "prometheus_release_name" {
  default = "prometheus"
}
variable "prometheus_domain" {
  default = "prometheus.home.beabys.com"
}
variable "alertmanager_domain" {
  default = "alertmanager.home.beabys.com"
}

# Loki
variable "loki_namespace" {
  default = "grafana-loki"
}
variable "loki_chart" {
  default = "grafana/loki-stack"
}
variable "loki_repo_url" {
  default = "https://grafana.github.io/helm-charts"
}
variable "loki_release_name" {
  default = "loki"
}
variable "loki_domain" {
  default = "loki.home.beabys.com"
}

# ArgoCD
variable "argocd_namespace" {
  default = "argo-cd"
}
variable "argocd_chart" {
  default = "argo-cd/argo-cd"
}
variable "argocd_repo_url" {
  default = "https://argoproj.github.io/argo-helm"
}
variable "argocd_release_name" {
  default = "argo-cd"
}
variable "argocd_domain" {
  default = "argocd.home.beabys.com"
}

# Fission
variable "fission_namespace" {
  default = "fission"
}
variable "fission_chart" {
  default = "fission-charts/fission-all"
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
  default = "functions.home.beabys.com"
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
  default = "external-secrets/external-secrets"
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