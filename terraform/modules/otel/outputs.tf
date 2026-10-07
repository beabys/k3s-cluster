output "status" {
  value = {
    name      = helm_release.otel.name
    namespace = helm_release.otel.namespace
    version   = helm_release.otel.version
  }
}
