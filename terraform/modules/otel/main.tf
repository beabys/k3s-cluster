resource "helm_release" "otel" {
  name             = var.otel_release_name
  repository       = var.otel_repo_url
  chart            = var.otel_chart
  version          = var.otel_version
  namespace        = var.otel_namespace
  create_namespace = true
  wait             = false
  timeout          = 600

  values = [
    file("${path.module}/files/otel-values.yaml")
  ]
}

resource "kubernetes_manifest" "servicemonitor" {
  count = var.enable_crd_manifests ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/files/otel-servicemonitor.yml", {
    otel_namespace = var.otel_namespace
    otel_release   = var.otel_release_name
  }))

  depends_on = [helm_release.otel]
}
