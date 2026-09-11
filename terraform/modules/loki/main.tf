resource "helm_release" "loki" {
  name             = var.loki_release_name
  repository       = var.loki_repo_url
  chart            = var.loki_chart
  namespace        = var.loki_namespace
  create_namespace = true

  values = [
    file("${path.module}/files/loki-values.yaml")
  ]
}

resource "kubernetes_manifest" "ingress" {
  manifest = yamldecode(templatefile("${path.module}/files/loki-ingress.yml", {
    loki_namespace = var.loki_namespace
    loki_domain    = var.loki_domain
  }))

  depends_on = [helm_release.loki]
}