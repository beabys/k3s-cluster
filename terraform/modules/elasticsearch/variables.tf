variable "elasticsearch_namespace" {}
variable "elasticsearch_chart" {}
variable "elasticsearch_repo_url" {}
variable "elasticsearch_release_name" {}
variable "elasticsearch_version" {}
variable "elasticsearch_storage_size" {
  default = "10Gi"
}
