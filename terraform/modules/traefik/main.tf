resource "helm_release" "traefik" {
  name             = var.traefik_release_name
  repository       = var.traefik_repo_url
  chart            = var.traefik_chart
  namespace        = var.traefik_namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/files/traefik-values.yaml", {
      traefik_dashboard_domain = var.traefik_dashboard_domain
    })
  ]
}

resource "kubernetes_secret" "dashboard_auth" {
  metadata {
    name      = "traefik-dashboard-auth"
    namespace = var.traefik_namespace
  }
  type = "Opaque"
  data = {
    users = base64encode("${var.traefik_dashboard_user}:${bcrypt(var.traefik_dashboard_password)}")
  }

  depends_on = [helm_release.traefik]
}

resource "kubernetes_manifest" "dashboard_middleware" {
  manifest = yamldecode(templatefile("${path.module}/files/dashboard-crd.yml", {
    traefik_namespace = var.traefik_namespace
  }))

  depends_on = [helm_release.traefik]
}