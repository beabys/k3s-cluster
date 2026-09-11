output "status" {
  value = {
    databases = [
      for db in var.external_databases : {
        name      = db.database_name
        namespace = db.namespace
      }
    ]
  }
}