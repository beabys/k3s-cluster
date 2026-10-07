resource "helm_release" "argocd" {
  name             = var.argocd_release_name
  repository       = var.argocd_repo_url
  chart            = var.argocd_chart
  version          = var.argocd_version
  namespace        = var.argocd_namespace
  create_namespace = true
  wait             = false
  timeout          = 600

  values = [
    templatefile("${path.module}/files/argocd-values.yaml", {
      argocd_domain = var.argocd_domain
    })
  ]
}

resource "kubernetes_manifest" "ingress" {
  manifest = yamldecode(templatefile("${path.module}/files/argocd-ingress.yml", {
    argocd_namespace = var.argocd_namespace
    argocd_domain    = var.argocd_domain
  }))

  depends_on = [helm_release.argocd]
}