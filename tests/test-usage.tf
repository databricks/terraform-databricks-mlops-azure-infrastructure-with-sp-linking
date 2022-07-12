terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 0.5.8"
    }
  }
}

provider "databricks" {
  alias = "dev"
}

provider "databricks" {
  alias = "staging"
}

provider "databricks" {
  alias = "prod"
}

module "mlops_azure_infrastructure_with_sp_linking" {
  source = "../."
  providers = {
    databricks.dev     = databricks.dev
    databricks.staging = databricks.staging
    databricks.prod    = databricks.prod
  }
  staging_workspace_id          = "123456789"
  prod_workspace_id             = "987654321"
  azure_staging_client_id       = "k9l8m7n6o5-e5f6-g7h8-i9j0-a1b2c3d4p4"
  azure_prod_client_id          = "k9l8m7n6p4-e5f6-g7h8-i9j0-a1b2c3d4o5"
  additional_token_usage_groups = ["users"] # This field is optional.
}