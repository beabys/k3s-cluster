output "status" {
  value = {
    name      = helm_release.argocd.name
    namespace = helm_release.argocd.namespace
    version   = helm_release.argocd.version
  }
}