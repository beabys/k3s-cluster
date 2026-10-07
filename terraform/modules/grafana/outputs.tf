output "status" {
  value = {
    name      = helm_release.grafana.name
    namespace = helm_release.grafana.namespace
    version   = helm_release.grafana.version
  }
}
