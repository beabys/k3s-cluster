output "status" {
  value = {
    managed    = var.manage_namespaces
    secrets    = [for e in local.secret_entries : { namespace = e.namespace, secret = e.secret_name }]
    namespaces = var.manage_namespaces ? tolist(local.distinct_ns) : []
  }
}
