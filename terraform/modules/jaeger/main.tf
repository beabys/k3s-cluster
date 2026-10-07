resource "helm_release" "jaeger" {
  name             = var.jaeger_release_name
  repository       = var.jaeger_repo_url
  chart            = var.jaeger_chart
  version          = var.jaeger_version
  namespace        = var.jaeger_namespace
  create_namespace = true
  wait             = false
  timeout          = 600

  values = [
    file("${path.module}/files/jaeger-values.yaml")
  ]
}

resource "kubernetes_manifest" "ingress" {
  manifest = yamldecode(templatefile("${path.module}/files/jaeger-ingress.yml", {
    jaeger_namespace = var.jaeger_namespace
    jaeger_domain    = var.jaeger_domain
    jaeger_release   = var.jaeger_release_name
  }))

  depends_on = [helm_release.jaeger]
}
