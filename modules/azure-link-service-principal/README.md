# Azure Link Service Principal Module

This module will link an existing Azure Active Directory (AAD) Application to a new Azure Databricks Service Principal in a workspace, outputting its application ID and AAD token. Instructions on how to create an AAD Application can be found [here](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/users-groups/service-principals#create-a-service-principal).

**_NOTE:_** The [Databricks provider](https://registry.terraform.io/providers/databricks/databricks/latest/docs) that is passed into the module must be configured with workspace admin permissions to allow service principal creation.

## Usage
### Option 1: Authentication with Azure Client Secret and Tenant ID
This option will use the client secret and tenant ID to generate an AAD token for authentication. The advantage to this approach is not having to manually generate short-lived AAD tokens (normally maximum lifetime of 60 minutes) each time this module needs to be used.

**_NOTE:_** This option requires that Python 3.8+ be installed to run `get-aad-token.py` to obtain the service principal's AAD token.
```hcl
provider "databricks" {} # Authenticate using preferred method as described in Databricks provider

module "azure_link_sp" {
  source = "databricks/azure-link-service-principal/databricks"
  providers = {
    databricks = databricks
  }
  display_name        = "example-name"
  group_name          = "example-group"
  azure_client_id     = "<client-id>"
  azure_client_secret = "<client-secret>"
  azure_tenant_id     = "<tenant-id>"
}
```

### Option 2: Authentication with Azure Active Directory (AAD) Token
This option will use the provided AAD token for authentication. The advantage to this approach is not having to create/provide a client secret and tenant ID.
```hcl
provider "databricks" {} # Authenticate using preferred method as described in Databricks provider

module "azure_link_sp" {
  source = "databricks/azure-link-service-principal/databricks"
  providers = {
    databricks = databricks
  }
  display_name    = "example-name"
  group_name      = "example-group"
  azure_client_id = "<client-id>"
  aad_token       = "<aad-token>"
}
```

## Requirements
| Name | Version |
|------|---------|
|[terraform](https://registry.terraform.io/)|\>=1.1.6|
|[databricks](https://registry.terraform.io/providers/databricks/databricks/0.5.8)|\>=0.5.8|
|[python](https://www.python.org/downloads/release/python-380/) \<Option 1\>|\>=3.8|

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
|display_name|The desired display name for the service principal in Azure Databricks.|string|N/A|yes|
|group_name|The Azure Databricks group name that the service principal will belong to. NOTE: The main purpose of this group is to give the service principal token usage permissions, so the group should have token usage permissions.|string|N/A|yes|
|azure_client_id|The Azure client ID of the Azure AD Service Principal to link to a Azure Databricks service principal. This client ID will be the application ID of the Databricks service principal.|string|N/A|yes|
|aad_token|The AAD Token belonging to the Azure AD Service Principal. NOTE: Only this or both azure_client_secret & azure_tenant_id need to be provided.|string|null|no|
|azure_client_secret|The Azure client secret of the Azure AD Service Principal. NOTE: If aad_token is not provided, this and azure_tenant_id must be provided to generate an AAD token.|string|null|no|
|azure_tenant_id|The Azure tenant ID of the Azure AD Service Principal. NOTE: If aad_token is not provided, this and azure_client_secret must be provided to generate an AAD token.|string|null|no|

## Outputs
| Name | Description | Type | Sensitive |
|------|-------------|------|---------|
|service_principal_application_id|Application ID of the created Azure Databricks service principal. This will be the same as the AAD Client ID.|string|no|
|service_principal_aad_token|Sensitive AAD token value of the created Azure Databricks service principal. NOTE: This token is short-lived, and if a long-term token is needed, this token can be used for service principal authentication into an Azure Databricks workspace to generate a long-lived personal access token (PAT) for the service principal.|string|yes|

## Providers
| Name | Authentication | Use |
|------|-------------|----|
|databricks|Provided by the user.|Generate all workspace resources except service principal PAT.|
|external \<Option 1\>|N/A|Run Python script that sends a POST request to Azure to obtain the service principal's AAD token.|

## Resources
| Name | Type |
|------|------|
|databricks_service_principal.sp|resource|
|databricks_group.sp_group|data source|
|databricks_group_member.add_sp_to_group|resource|
|external.token \<Option 1\>|data source|

## Known Issues
- AAD token generation occasionally fails with `"HTTP Error 400: Bad Request"` but the query is not actually invalid.
    - Solution: Re-run `terraform apply` and the error should disappear.