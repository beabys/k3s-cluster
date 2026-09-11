# Wire all 9 component modules. Order matters: traefik first (ingress),
# metallb second (restarts traefik to pick up LoadBalancer IP).

module "traefik" {
  source = "./modules/traefik"

  traefik_namespace        = var.traefik_namespace
  traefik_chart            = var.traefik_chart
  traefik_repo_url         = var.traefik_repo_url
  traefik_release_name     = var.traefik_release_name
  traefik_dashboard_user   = var.traefik_dashboard_user
  traefik_dashboard_password = var.traefik_dashboard_password
  traefik_dashboard_domain = var.traefik_dashboard_domain
}

module "metallb" {
  source = "./modules/metallb"

  metallb_namespace     = var.metallb_namespace
  metallb_chart         = var.metallb_chart
  metallb_repo_url      = var.metallb_repo_url
  metallb_release_name  = var.metallb_release_name
  metallb_ip_pool_range = var.metallb_ip_pool_range
  traefik_namespace     = var.traefik_namespace
  traefik_release_name  = var.traefik_release_name

  depends_on = [module.traefik]
}

module "longhorn" {
  source = "./modules/longhorn"

  longhorn_namespace    = var.longhorn_namespace
  longhorn_chart        = var.longhorn_chart
  longhorn_repo_url     = var.longhorn_repo_url
  longhorn_release_name = var.longhorn_release_name
  longhorn_version      = var.longhorn_version
  longhorn_domain       = var.longhorn_domain

  depends_on = [module.traefik]
}

module "prometheus" {
  source = "./modules/prometheus"

  prometheus_namespace    = var.prometheus_namespace
  prometheus_chart        = var.prometheus_chart
  prometheus_repo_url     = var.prometheus_repo_url
  prometheus_release_name = var.prometheus_release_name
  prometheus_domain       = var.prometheus_domain
  alertmanager_domain     = var.alertmanager_domain

  depends_on = [module.traefik]
}

module "loki" {
  source = "./modules/loki"

  loki_namespace    = var.loki_namespace
  loki_chart        = var.loki_chart
  loki_repo_url     = var.loki_repo_url
  loki_release_name = var.loki_release_name
  loki_domain       = var.loki_domain

  depends_on = [module.traefik]
}

module "argocd" {
  source = "./modules/argocd"

  argocd_namespace    = var.argocd_namespace
  argocd_chart        = var.argocd_chart
  argocd_repo_url     = var.argocd_repo_url
  argocd_release_name = var.argocd_release_name
  argocd_domain       = var.argocd_domain

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
  fission_domain            = var.fission_domain
  fission_crd_kustomize_url = var.fission_crd_kustomize_url
  fission_deploy_examples   = var.fission_deploy_examples

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
}