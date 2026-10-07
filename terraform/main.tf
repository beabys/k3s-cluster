# Wire all 12 component modules. Order matters: traefik first (ingress),
# metallb second (restarts traefik to pick up LoadBalancer IP).
# Modules: traefik, metallb, longhorn, prometheus, elasticsearch, jaeger,
# otel, grafana, argocd, external_db, fission, external_secrets.

locals {
  traefik_dashboard_domain = coalesce(var.traefik_dashboard_domain, "traefik.${var.domain}")
  longhorn_domain          = coalesce(var.longhorn_domain, "longhorn.${var.domain}")
  prometheus_domain        = coalesce(var.prometheus_domain, "prometheus.${var.domain}")
  alertmanager_domain      = coalesce(var.alertmanager_domain, "alertmanager.${var.domain}")
  jaeger_domain            = coalesce(var.jaeger_domain, "jaeger.${var.domain}")
  grafana_domain           = coalesce(var.grafana_domain, "grafana.${var.domain}")
  argocd_domain            = coalesce(var.argocd_domain, "argocd.${var.domain}")
  fission_domain           = coalesce(var.fission_domain, "functions.${var.domain}")
}

module "traefik" {
  source = "./modules/traefik"

  traefik_namespace          = var.traefik_namespace
  traefik_chart              = var.traefik_chart
  traefik_repo_url           = var.traefik_repo_url
  traefik_version            = var.traefik_version
  traefik_release_name       = var.traefik_release_name
  traefik_dashboard_user     = var.traefik_dashboard_user
  traefik_dashboard_password = var.traefik_dashboard_password
  traefik_dashboard_domain   = local.traefik_dashboard_domain
  enable_crd_manifests       = var.enable_crd_manifests
}

module "metallb" {
  source = "./modules/metallb"

  metallb_namespace     = var.metallb_namespace
  metallb_chart         = var.metallb_chart
  metallb_repo_url      = var.metallb_repo_url
  metallb_version       = var.metallb_version
  metallb_release_name  = var.metallb_release_name
  metallb_ip_pool_range = var.metallb_ip_pool_range
  traefik_namespace     = var.traefik_namespace
  traefik_release_name  = var.traefik_release_name
  enable_crd_manifests  = var.enable_crd_manifests

  depends_on = [module.traefik]
}

module "longhorn" {
  source = "./modules/longhorn"

  longhorn_namespace    = var.longhorn_namespace
  longhorn_chart        = var.longhorn_chart
  longhorn_repo_url     = var.longhorn_repo_url
  longhorn_release_name = var.longhorn_release_name
  longhorn_version      = var.longhorn_version
  longhorn_domain       = local.longhorn_domain

  depends_on = [module.traefik]
}

module "prometheus" {
  source = "./modules/prometheus"

  prometheus_namespace    = var.prometheus_namespace
  prometheus_chart        = var.prometheus_chart
  prometheus_repo_url     = var.prometheus_repo_url
  prometheus_version      = var.prometheus_version
  prometheus_release_name = var.prometheus_release_name
  prometheus_domain       = local.prometheus_domain
  alertmanager_domain     = local.alertmanager_domain

  depends_on = [module.traefik, module.longhorn]
}

module "elasticsearch" {
  source = "./modules/elasticsearch"

  elasticsearch_namespace    = var.elasticsearch_namespace
  elasticsearch_chart        = var.elasticsearch_chart
  elasticsearch_repo_url     = var.elasticsearch_repo_url
  elasticsearch_release_name = var.elasticsearch_release_name
  elasticsearch_version      = var.elasticsearch_version
  elasticsearch_storage_size = var.elasticsearch_storage_size

  depends_on = [module.longhorn]
}

module "jaeger" {
  source = "./modules/jaeger"

  jaeger_namespace    = var.jaeger_namespace
  jaeger_chart        = var.jaeger_chart
  jaeger_repo_url     = var.jaeger_repo_url
  jaeger_release_name = var.jaeger_release_name
  jaeger_version      = var.jaeger_version
  jaeger_domain       = local.jaeger_domain

  depends_on = [module.elasticsearch]
}

module "otel" {
  source = "./modules/otel"

  otel_namespace       = var.otel_namespace
  otel_chart           = var.otel_chart
  otel_repo_url        = var.otel_repo_url
  otel_release_name    = var.otel_release_name
  otel_version         = var.otel_version
  enable_crd_manifests = var.enable_crd_manifests

  depends_on = [module.elasticsearch, module.jaeger]
}

module "grafana" {
  source = "./modules/grafana"

  grafana_namespace      = var.grafana_namespace
  grafana_chart          = var.grafana_chart
  grafana_repo_url       = var.grafana_repo_url
  grafana_release_name   = var.grafana_release_name
  grafana_version        = var.grafana_version
  grafana_domain         = local.grafana_domain
  grafana_admin_password = var.grafana_admin_password

  depends_on = [module.traefik, module.longhorn]
}

module "argocd" {
  source = "./modules/argocd"

  argocd_namespace    = var.argocd_namespace
  argocd_chart        = var.argocd_chart
  argocd_repo_url     = var.argocd_repo_url
  argocd_version      = var.argocd_version
  argocd_release_name = var.argocd_release_name
  argocd_domain       = local.argocd_domain

  depends_on = [module.traefik]
}

module "external_db" {
  source = "./modules/external-db"

  external_databases = var.external_databases
}

module "fission" {
  source = "./modules/fission"

  fission_namespace         = var.fission_namespace
  fission_chart             = var.fission_chart
  fission_repo_url          = var.fission_repo_url
  fission_release_name      = var.fission_release_name
  fission_version           = var.fission_version
  fission_domain            = local.fission_domain
  fission_crd_kustomize_url = var.fission_crd_kustomize_url
  fission_deploy_examples   = var.fission_deploy_examples
  enable_crd_manifests      = var.enable_crd_manifests

  depends_on = [module.traefik]
}

module "external_secrets" {
  source = "./modules/external-secrets"

  eso_namespace             = var.eso_namespace
  eso_chart                 = var.eso_chart
  eso_repo_url              = var.eso_repo_url
  eso_release_name          = var.eso_release_name
  eso_version               = var.eso_version
  eso_install_crds          = var.eso_install_crds
  eso_aws_emulator_endpoint = var.eso_aws_emulator_endpoint
  eso_aws_access_key_id     = var.eso_aws_access_key_id
  eso_aws_secret_access_key = var.eso_aws_secret_access_key
  eso_aws_cluster_stores    = var.eso_aws_cluster_stores
  enable_crd_manifests      = var.enable_crd_manifests
}

module "registry_secrets" {
  source = "./modules/registry-secrets"

  registry_secrets  = var.registry_secrets
  manage_namespaces = var.registry_manage_namespaces
}