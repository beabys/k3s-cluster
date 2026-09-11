resource "helm_release" "metallb" {
  name             = var.metallb_release_name
  repository       = var.metallb_repo_url
  chart            = var.metallb_chart
  namespace        = var.metallb_namespace
  create_namespace = true
  wait             = true
  timeout          = 90
}

resource "terraform_data" "metallb_webhook_ready" {
  provisioner "local-exec" {
    command = "kubectl wait --namespace ${var.metallb_namespace} --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s"
  }

  depends_on = [helm_release.metallb]
}

resource "kubernetes_manifest" "ip_pool" {
  manifest = yamldecode(templatefile("${path.module}/files/metallb-ippool.yml", {
    metallb_namespace     = var.metallb_namespace
    metallb_ip_pool_range = var.metallb_ip_pool_range
  }))

  depends_on = [terraform_data.metallb_webhook_ready]
}

resource "kubernetes_manifest" "l2_advertisement" {
  manifest = yamldecode(templatefile("${path.module}/files/metallb-l2adv.yml", {
    metallb_namespace = var.metallb_namespace
  }))

  depends_on = [terraform_data.metallb_webhook_ready]
}

# Ansible restarts Traefik after MetalLB install so it picks up the
# LoadBalancer IP. Mirrored here; module.traefik dependency enforced at root.
resource "terraform_data" "traefik_restart" {
  provisioner "local-exec" {
    command = "kubectl rollout restart deployment ${var.traefik_release_name} -n ${var.traefik_namespace} && kubectl rollout status deployment ${var.traefik_release_name} -n ${var.traefik_namespace} --timeout=120s"
  }

  depends_on = [kubernetes_manifest.ip_pool, kubernetes_manifest.l2_advertisement]
}