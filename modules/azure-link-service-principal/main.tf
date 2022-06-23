variable "display_name" {
  type        = string
  description = "The display name for the service principal in Databricks."
}

variable "group_name" {
  type        = string
  description = "The Databricks group name that the service principal will belong to. NOTE: The main purpose of this group is to give the service principal token usage permissions, so the group should have token usage permissions."
}

variable "azure_client_id" {
  type        = string
  description = "The Azure client ID of the Azure AD Service Principal to link to a Databricks service principal. This client ID will be the application ID of the Databricks service principal."
}

variable "aad_token" {
  type        = string
  description = "The AAD Token belonging to the Azure AD Service Principal. NOTE: Only this or both azure_client_secret & azure_tenant_id need to be provided."
  default     = null
  nullable    = true
}

variable "azure_client_secret" {
  type        = string
  description = "The Azure client secret of the Azure AD Service Principal. NOTE: If aad_token is not provided, this and azure_tenant_id must be provided to generate an AAD token."
  default     = null
  nullable    = true
}

variable "azure_tenant_id" {
  type        = string
  description = "The Azure tenant ID of the Azure AD Service Principal. NOTE: If aad_token is not provided, this and azure_client_secret must be provided to generate an AAD token."
  default     = null
  nullable    = true
}

resource "databricks_service_principal" "sp" {
  application_id = var.azure_client_id
  display_name   = var.display_name
}

data "databricks_group" "sp_group" {
  display_name = var.group_name
}

resource "databricks_group_member" "add_sp_to_group" {
  group_id  = data.databricks_group.sp_group.id
  member_id = databricks_service_principal.sp.id
}

data "external" "token" {
  count   = var.aad_token == null ? 1 : 0
  program = ["python", "${path.module}/get-aad-token.py"]
  query = {
    client_id     = var.azure_client_id
    client_secret = var.azure_client_secret
    tenant_id     = var.azure_tenant_id
  }
  depends_on = [databricks_group_member.add_sp_to_group]
}

output "service_principal_application_id" {
  value       = databricks_service_principal.sp.application_id
  description = "Application ID of the created Azure Databricks service principal."
}

output "service_principal_aad_token" {
  value       = var.aad_token == null ? data.external.token[0].result.token : var.aad_token
  sensitive   = true
  description = "Sensitive AAD token value of the created Azure Databricks service principal."
}
