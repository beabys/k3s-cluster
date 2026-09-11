variable "external_databases" {
  type = list(object({
    namespace              = string
    database_name          = string
    database_internal_port = number
    database_host_port     = number
    database_host          = string
  }))
  default = []
}