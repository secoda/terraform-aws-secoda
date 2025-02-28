module "backup" {
  source           = "cloudposse/backup/aws"
  version          = "1.0.2"
  stage            = var.backup_name == null ? terraform.workspace : var.backup_name
  name             = var.name
  backup_resources = [aws_db_instance.postgres.arn]
  not_resources    = []
  
  backup_vault_lock_configuration = {
    changeable_for_days = 7
    max_retention_days  = 60
    min_retention_days  = 14
  }

  rules = [
    {
      name = "secoda-db-daily"
      schedule : "cron(0 5 ? * * *)"
      start_window      = 320
      completion_window = 10080
      delete_after      = 35
    }
  ]
}
