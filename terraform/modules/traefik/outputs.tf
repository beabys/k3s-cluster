output "status" {
  value = {
    name      = helm_release.traefik.name
    namespace = helm_release.traefik.namespace
    version   = helm_release.traefik.version
  }
}