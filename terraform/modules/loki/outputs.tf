output "status" {
  value = {
    name      = helm_release.loki.name
    namespace = helm_release.loki.namespace
    version   = helm_release.loki.version
  }
}