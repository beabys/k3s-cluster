resource "helm_release" "external_secrets" {
  name             = var.eso_release_name
  repository       = var.eso_repo_url
  chart            = var.eso_chart
  namespace        = var.eso_namespace
  create_namespace = true
  version          = var.eso_version

  set {
    name  = "installCRDs"
    value = tostring(var.eso_install_crds)
  }

  dynamic "set_sensitive" {
    for_each = var.eso_aws_emulator_endpoint != "" ? [1] : []
    content {
      name  = "extraEnv"
      value = yamlencode([{ name = "AWS_SECRETSMANAGER_ENDPOINT", value = var.eso_aws_emulator_endpoint }])
    }
  }
}

resource "kubernetes_secret" "eso_aws_creds" {
  count = length(var.eso_aws_cluster_stores) > 0 ? 1 : 0

  metadata {
    name      = "eso-aws-creds"
    namespace = var.eso_namespace
  }

  type = "Opaque"

  data = {
    "access-key"        = base64encode(var.eso_aws_access_key_id)
    "secret-access-key" = base64encode(var.eso_aws_secret_access_key)
  }

  depends_on = [helm_release.external_secrets]
}

resource "kubernetes_manifest" "cluster_secret_store" {
  for_each = { for s in var.eso_aws_cluster_stores : s.name => s }

  manifest = yamldecode(templatefile("${path.module}/files/cluster-secret-store.yml", {
    name          = each.value.name
    region        = each.value.region
    service       = each.value.service
    eso_namespace = var.eso_namespace
  }))

  depends_on = [kubernetes_secret.eso_aws_creds]
}