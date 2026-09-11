resource "helm_release" "prometheus" {
  name             = var.prometheus_release_name
  repository       = var.prometheus_repo_url
  chart            = var.prometheus_chart
  namespace        = var.prometheus_namespace
  create_namespace = true

  values = [
    file("${path.module}/files/prometheus-values.yaml")
  ]
}

resource "kubernetes_manifest" "prometheus_ingress" {
  manifest = yamldecode(templatefile("${path.module}/files/prometheus-ingress.yml", {
    prometheus_namespace = var.prometheus_namespace
    prometheus_domain    = var.prometheus_domain
  }))

  depends_on = [helm_release.prometheus]
}

resource "kubernetes_manifest" "alertmanager_ingress" {
  manifest = yamldecode(templatefile("${path.module}/files/alertmanager-ingress.yml", {
    prometheus_namespace = var.prometheus_namespace
    alertmanager_domain  = var.alertmanager_domain
  }))

  depends_on = [helm_release.prometheus]
}