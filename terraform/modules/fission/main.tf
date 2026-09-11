resource "terraform_data" "fission_crds" {
  provisioner "local-exec" {
    command = "kubectl apply --server-side --field-manager kubectl -k ${var.fission_crd_kustomize_url}"
  }
}

resource "helm_release" "fission" {
  name             = var.fission_release_name
  repository       = var.fission_repo_url
  chart            = var.fission_chart
  namespace        = var.fission_namespace
  create_namespace = true
  version          = var.fission_version
  timeout          = 600

  values = [
    file("${path.module}/files/fission-values.yaml")
  ]

  depends_on = [terraform_data.fission_crds]
}

resource "kubernetes_manifest" "router_ingress" {
  manifest = yamldecode(templatefile("${path.module}/files/router-ingress.yml", {
    fission_namespace = var.fission_namespace
    fission_domain    = var.fission_domain
  }))

  depends_on = [helm_release.fission]
}

resource "kubernetes_manifest" "env_python_warm" {
  count = var.fission_deploy_examples ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/files/env-python-warm.yml", {
    fission_namespace = var.fission_namespace
  }))

  depends_on = [helm_release.fission]
}

resource "kubernetes_manifest" "hello_world_package" {
  count = var.fission_deploy_examples ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/files/hello-world-package.yml", {
    fission_namespace = var.fission_namespace
  }))

  depends_on = [helm_release.fission, kubernetes_manifest.env_python_warm]
}

resource "kubernetes_manifest" "hello_world_function" {
  count = var.fission_deploy_examples ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/files/hello-world-function.yml", {
    fission_namespace = var.fission_namespace
  }))

  depends_on = [kubernetes_manifest.hello_world_package]
}

resource "kubernetes_manifest" "hello_world_httptrigger" {
  count = var.fission_deploy_examples ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/files/hello-world-httptrigger.yml", {
    fission_namespace = var.fission_namespace
  }))

  depends_on = [kubernetes_manifest.hello_world_function]
}