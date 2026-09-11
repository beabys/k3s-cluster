variable "eso_namespace" {}
variable "eso_chart" {}
variable "eso_repo_url" {}
variable "eso_release_name" {}
variable "eso_version" {}
variable "eso_install_crds" {
  default = true
}
variable "eso_aws_emulator_endpoint" {
  default = ""
}
variable "eso_aws_access_key_id" {
  default = ""
}
variable "eso_aws_secret_access_key" {
  default = ""
}
variable "eso_aws_cluster_stores" {
  type = list(object({
    name    = string
    region  = string
    service = string
  }))
  default = []
}