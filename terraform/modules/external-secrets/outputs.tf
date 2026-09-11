output "status" {
  value = {
    name      = helm_release.external_secrets.name
    namespace = helm_release.external_secrets.namespace
    version   = helm_release.external_secrets.version
  }
}