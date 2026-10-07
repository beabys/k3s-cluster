output "status" {
  value = {
    name      = helm_release.jaeger.name
    namespace = helm_release.jaeger.namespace
    version   = helm_release.jaeger.version
  }
}
