resource "helm_release" "grafana" {
  name             = var.grafana_release_name
  repository       = var.grafana_repo_url
  chart            = var.grafana_chart
  version          = var.grafana_version
  namespace        = var.grafana_namespace
  create_namespace = true
  wait             = false
  timeout          = 600

  values = [
    file("${path.module}/files/grafana-values.yaml")
  ]

  set {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }
}

resource "kubernetes_manifest" "ingress" {
  manifest = yamldecode(templatefile("${path.module}/files/grafana-ingress.yml", {
    grafana_namespace = var.grafana_namespace
    grafana_domain    = var.grafana_domain
  }))

  depends_on = [helm_release.grafana]
}
