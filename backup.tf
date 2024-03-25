module "backup" {
  source           = "cloudposse/backup/aws"
  version          = "~> 1.0"
  stage            = var.backup_name == null ? terraform.workspace : var.backup_name
  name             = var.name
  backup_resources = [aws_db_instance.postgres.arn]
  not_resources    = []
  rules = [
    {
      name              = "secoda-db-daily"
      schedule          = "cron(0 5 * * ? *)"
      start_window      = 120
      completion_window = 720
      delete_after      = 30
    }
  ]
}

resource "aws_backup_vault_lock_configuration" "backup_lock" {
  backup_vault_name   = module.backup.backup_vault_id
  changeable_for_days = 3
  max_retention_days  = 365
  min_retention_days  = 7
}
