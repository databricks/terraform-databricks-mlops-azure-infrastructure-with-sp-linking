variable "staging_workspace_id" {
  type        = string
  description = "Workspace ID of the staging workspace (can be often found in the URL) used for remote model registry setup."
}

variable "prod_workspace_id" {
  type        = string
  description = "Workspace ID of the prod workspace (can be often found in the URL) used for remote model registry setup."
}

variable "azure_staging_client_id" {
  type        = string
  description = "The client ID of the AAD service principal in the staging workspace that will be used to READ the model registry from the dev workspace."
}

variable "azure_staging_aad_token" {
  type        = string
  description = "The AAD token of the service principal in the staging workspace. This will need to be manually refreshed once it expires (often within several minutes). NOTE: Only this or both azure_staging_client_secret & azure_staging_tenant_id need to be provided."
  default     = null
  nullable    = true
}

variable "azure_staging_client_secret" {
  type        = string
  description = "The client secret of the AAD service principal in the staging workspace. NOTE: If azure_staging_aad_token is not provided, this and azure_staging_tenant_id must be provided to generate an AAD token."
  default     = null
  nullable    = true
}

variable "azure_staging_tenant_id" {
  type        = string
  description = "The tenant ID of the AAD service principal in the staging workspace. NOTE: If azure_staging_aad_token is not provided, this and azure_staging_client_secret must be provided to generate an AAD token."
  default     = null
  nullable    = true
}

variable "azure_prod_client_id" {
  type        = string
  description = "The client ID of the AAD service principal in the prod workspace that will be used to READ the model registry from the dev & staging workspaces."
}

variable "azure_prod_aad_token" {
  type        = string
  description = "The AAD token of the service principal in the prod workspace. This will need to be manually refreshed once it expires (often within several minutes). NOTE: Only this or both azure_prod_client_secret & azure_prod_tenant_id need to be provided."
  default     = null
  nullable    = true
}

variable "azure_prod_client_secret" {
  type        = string
  description = "The client secret of the AAD service principal in the prod workspace. NOTE: If azure_prod_aad_token is not provided, this and azure_prod_tenant_id must be provided to generate an AAD token."
  default     = null
  nullable    = true
}

variable "azure_prod_tenant_id" {
  type        = string
  description = "The tenant ID of the AAD service principal in the prod workspace. NOTE: If azure_prod_aad_token is not provided, this and azure_prod_client_secret must be provided to generate an AAD token."
  default     = null
  nullable    = true
}

variable "additional_token_usage_groups" {
  type        = list(string)
  description = "List of groups that should have token usage permissions in the staging and prod workspaces, along with the created service principal group (mlops-service-principals). By default, it is empty."
  default     = []
}
