output "traefik" {
  value = module.traefik.status
}

output "metallb" {
  value = module.metallb.status
}

output "longhorn" {
  value = module.longhorn.status
}

output "prometheus" {
  value = module.prometheus.status
}

output "loki" {
  value = module.loki.status
}

output "argocd" {
  value = module.argocd.status
}

output "external_db" {
  value = module.external_db.status
}

output "fission" {
  value = module.fission.status
}

output "external_secrets" {
  value = module.external_secrets.status
}