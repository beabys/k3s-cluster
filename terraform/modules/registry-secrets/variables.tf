variable "registry_secrets" {
  description = "List of private-registry credentials entries. Empty list = no resources created."
  type = list(object({
    secret_name = string
    server      = string
    username    = string
    password    = string
    namespaces  = list(string)
  }))
  default = []
}

variable "manage_namespaces" {
  description = "Create target namespaces if missing. Set false when namespaces already exist (e.g. managed by ArgoCD) to avoid import."
  type        = bool
  default     = true
}
