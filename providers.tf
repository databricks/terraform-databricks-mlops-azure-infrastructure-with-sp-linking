terraform {
  required_providers {
    databricks = {
      source                = "databricks/databricks"
      version               = ">= 0.5.8"
      configuration_aliases = [databricks.dev, databricks.staging, databricks.prod]
    }
  }
}

provider "databricks" {
  alias = "staging_sp"
  host  = data.databricks_current_user.staging_user.workspace_url
  token = module.link_staging_sp.service_principal_aad_token
}

provider "databricks" {
  alias = "prod_sp"
  host  = data.databricks_current_user.prod_user.workspace_url
  token = module.link_prod_sp.service_principal_aad_token
}
