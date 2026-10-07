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

output "elasticsearch" {
  value = module.elasticsearch.status
}

output "jaeger" {
  value = module.jaeger.status
}

output "otel" {
  value = module.otel.status
}

output "grafana" {
  value = module.grafana.status
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

output "registry_secrets" {
  value = module.registry_secrets.status
}