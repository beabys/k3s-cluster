# Registry pull secrets — data-driven. Empty list = zero resources.
# Creates namespaces (if manage_namespaces=true) and per-namespace
# kubernetes.io/dockerconfigjson image-pull secrets.

locals {
  # Flatten: one entry per (namespace, secret) pair.
  secret_entries = flatten([
    for entry in var.registry_secrets : [
      for ns in entry.namespaces : {
        key         = "${ns}/${entry.secret_name}"
        namespace   = ns
        secret_name = entry.secret_name
        server      = entry.server
        username    = entry.username
        password    = entry.password
      }
    ]
  ])

  secret_map  = { for e in local.secret_entries : e.key => e }
  distinct_ns = toset(flatten([for e in var.registry_secrets : e.namespaces]))
}

resource "kubernetes_namespace_v1" "this" {
  for_each = var.manage_namespaces ? local.distinct_ns : toset([])

  metadata {
    name = each.key
  }
}

resource "kubernetes_secret_v1" "registry" {
  for_each = local.secret_map

  metadata {
    name      = each.value.secret_name
    namespace = each.value.namespace
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (each.value.server) = {
          username = each.value.username
          password = each.value.password
          auth     = base64encode("${each.value.username}:${each.value.password}")
        }
      }
    })
  }

  depends_on = [kubernetes_namespace_v1.this]
}
