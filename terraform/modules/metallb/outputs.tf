output "status" {
  value = {
    name      = helm_release.metallb.name
    namespace = helm_release.metallb.namespace
    version   = helm_release.metallb.version
  }
}