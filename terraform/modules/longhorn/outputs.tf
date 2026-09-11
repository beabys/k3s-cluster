output "status" {
  value = {
    name      = helm_release.longhorn.name
    namespace = helm_release.longhorn.namespace
    version   = helm_release.longhorn.version
  }
}