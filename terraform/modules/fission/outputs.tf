output "status" {
  value = {
    name      = helm_release.fission.name
    namespace = helm_release.fission.namespace
    version   = helm_release.fission.version
  }
}