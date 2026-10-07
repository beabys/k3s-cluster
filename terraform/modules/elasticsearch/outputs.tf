output "status" {
  value = {
    name      = helm_release.elasticsearch.name
    namespace = helm_release.elasticsearch.namespace
    version   = helm_release.elasticsearch.version
  }
}
