variable "otel_namespace" {}
variable "otel_chart" {}
variable "otel_repo_url" {}
variable "otel_release_name" {}
variable "otel_version" {}
variable "jaeger_endpoint" {
  default = "jaeger.jaeger.svc.cluster.local:4317"
}
variable "elasticsearch_endpoint" {
  default = "http://elasticsearch-master.elasticsearch.svc.cluster.local:9200"
}
variable "enable_crd_manifests" {
  type = bool
}
