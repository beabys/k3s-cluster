resource "helm_release" "elasticsearch" {
  name             = var.elasticsearch_release_name
  repository       = var.elasticsearch_repo_url
  chart            = var.elasticsearch_chart
  version          = var.elasticsearch_version
  namespace        = var.elasticsearch_namespace
  create_namespace = true
  wait             = false
  timeout          = 900

  values = [
    file("${path.module}/files/elasticsearch-values.yaml")
  ]
}
