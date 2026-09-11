output "status" {
  value = {
    name      = helm_release.prometheus.name
    namespace = helm_release.prometheus.namespace
    version   = helm_release.prometheus.version
  }
}