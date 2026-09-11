# longhornctl preflight (download + install/check) is skipped in v1 — the
# Helm chart installs the operator and storage classes directly. Revisit if
# node-level preflight checks are required.

resource "helm_release" "longhorn" {
  name             = var.longhorn_release_name
  repository       = var.longhorn_repo_url
  chart            = var.longhorn_chart
  namespace        = var.longhorn_namespace
  create_namespace = true
  version          = var.longhorn_version

  values = [
    file("${path.module}/files/longhorn-values.yaml")
  ]
}

resource "kubernetes_manifest" "ingress" {
  manifest = yamldecode(templatefile("${path.module}/files/longhorn-ingress.yml", {
    longhorn_namespace = var.longhorn_namespace
    longhorn_domain    = var.longhorn_domain
  }))

  depends_on = [helm_release.longhorn]
}