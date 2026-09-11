resource "kubernetes_namespace" "db" {
  for_each = toset(var.external_databases[*].namespace)

  metadata {
    name = each.key
  }
}

resource "kubernetes_service" "db" {
  for_each = { for db in var.external_databases : "${db.namespace}/${db.database_name}" => db }

  metadata {
    name      = each.value.database_name
    namespace = each.value.namespace
  }

  spec {
    port {
      name        = each.value.database_name
      protocol    = "TCP"
      port        = each.value.database_internal_port
      target_port = each.value.database_host_port
    }
  }

  depends_on = [kubernetes_namespace.db]
}

resource "kubernetes_endpoint_slice_v1" "db" {
  for_each = { for db in var.external_databases : "${db.namespace}/${db.database_name}" => db }

  metadata {
    name      = each.value.database_name
    namespace = each.value.namespace
    labels = {
      "kubernetes.io/service-name" = each.value.database_name
    }
  }

  address_type = "IPv4"

  endpoint {
    addresses = [each.value.database_host]
  }

  port {
    name         = each.value.database_name
    protocol     = "TCP"
    app_protocol = "TCP"
    port         = each.value.database_host_port
  }

  depends_on = [kubernetes_namespace.db]
}