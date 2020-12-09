provider "aws" {
  region = "eu-central-1"
}

locals {
  user_tag = {
    Owner = var.awsusername
    Test  = "Backup"
  }
  ec2_tag_public         = { server_type = "public" }
  ec2_tag_private        = { server_type = "private" }
  ec2_tag_database       = { server_type = "database" }
  security_group_tag_ec2 = { scope = "security_server" }
}


module "aws_backup_example" {
  source = "../../modules_AWS/terraform-aws-backup-master"

  # Vault
  vault_name = "vault-3"

  # Plan
  plan_name = "complete-plan"

  # Multiple rules using a list of maps
  rules = [
    {
      name              = "rule-1"
      schedule          = "cron(45 15 * * ? *)"
      target_vault_name = null
      start_window      = 60
      completion_window = 120
      lifecycle = {
        cold_storage_after = 0
        delete_after       = 90
      },
      copy_action = {
        lifecycle = {
          cold_storage_after = 0
          delete_after       = 90
        },
        destination_vault_arn = "arn:aws:backup:eu-central-1:152371567679:backup-vault:Default"
      }
      recovery_point_tags = local.user_tag
    },
  ]

  # Multiple selections
  #  - Selection-1: By resources and tag
  #  - Selection-2: Only by resources
  selections = [
    {
      name = "selection-1"
      //resources = ["arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table1"]
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "server_type"
        value = "public"
      }
    },
  ]

  tags = local.user_tag
}
