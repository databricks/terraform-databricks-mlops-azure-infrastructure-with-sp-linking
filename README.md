# MLOps Azure Infrastructure Module with Service Principal Linking

This module sets up [multi-workspace model registry](https://docs.microsoft.com/en-us/azure/databricks/applications/machine-learning/manage-model-lifecycle/multiple-workspaces) between a development (dev) workspace, a staging workspace, and a production (prod) workspace, allowing READ access from dev/staging workspaces to staging & prod model registries.

The module performs this setup by linking [pre-existing AAD applications](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/users-groups/service-principals#create-a-service-principal) with newly created Azure Databricks service principals in the staging and prod workspaces, then giving them READ-only access to their respective model registries. It will also create secret scopes and store the necessary secrets in the dev and staging workspaces, and only give READ access to this secret scope to the `"users"` group and the generated service principals group. The output of this module will be the secret scope names and prefixes since these values are needed to be able to [access the remote model registry](https://docs.microsoft.com/en-us/azure/databricks/applications/machine-learning/manage-model-lifecycle/multiple-workspaces#specify-a-remote-registry).

**_NOTE:_**
1. This module is in preview so it is still experimental and subject to change. Feedback is welcome!
2. The [Databricks providers](https://registry.terraform.io/providers/databricks/databricks/latest/docs) that are passed into the module must be configured with workspace admin permissions.
3. In order to create tokens for service principals, they are added to a group, which is then given `token_usage` [permission](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/permissions#token-usage). However, in order to set this permission, there must be [at least 1 personal access token in the workspace](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/permissions#token-usage), and this permission [strictly overwrites existing permissions](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/obo_token#example-usage). Currently, running this module will overwrite permissions to allow token usage only for members of the generated service principals group in the staging and prod workspaces. If additional groups are desired to have `token_usage` permissions, they can be set via the `additional_token_usage_groups` input variable.
4. The service principal tokens stored for remote model registry access are created with a default expiration of 100 days (8640000 seconds), and the module will need to be re-applied after this time to refresh the tokens.

## Usage
### Option 1: Authentication with Azure Client Secret and Tenant ID
This option will use the client secrets and tenant IDs to generate AAD tokens for authentication. The advantage to this approach is not having to manually generate short-lived AAD tokens (normally maximum lifetime of 60 minutes) each time this module needs to be used.

**_NOTE:_** This option requires that Python 3.8+ be installed to obtain the service principal's AAD token.
```hcl
provider "databricks" {
  alias = "dev"    # Authenticate using preferred method as described in Databricks provider
}

provider "databricks" {
  alias = "staging"     # Authenticate using preferred method as described in Databricks provider
}

provider "databricks" {
  alias = "prod"     # Authenticate using preferred method as described in Databricks provider
}

module "mlops_azure_infrastructure_with_sp_linking" {
  source = "databricks/mlops-azure-infrastructure-with-sp-linking/databricks"
  providers = {
    databricks.dev = databricks.dev
    databricks.staging = databricks.staging
    databricks.prod = databricks.prod
  }
  staging_workspace_id          = "123456789"
  prod_workspace_id             = "987654321"
  azure_staging_client_id       = "k9l8m7n6o5-e5f6-g7h8-i9j0-a1b2c3d4p4"
  azure_staging_client_secret   = var.azure_staging_client_secret     # This value is sensitive.
  azure_staging_tenant_id       = "a1b2c3d4-e5f6-g7h8-i9j0-k9l8m7n6o5p4"
  azure_prod_client_id          = "k9l8m7n6p4-e5f6-g7h8-i9j0-a1b2c3d4o5"
  azure_prod_client_secret      = var.azure_prod_client_secret     # This value is sensitive.
  azure_prod_tenant_id          = "a1b2c3d4-e5f6-g7h8-i9j0-k9l8m7n6o5p4"
  additional_token_usage_groups = ["users"]     # This field is optional.
}
```

### Option 2: Authentication with Azure Active Directory (AAD) Token
This option will use the provided AAD tokens for authentication. The advantage to this approach is not having to create/provide client secrets and tenant IDs.
```hcl
provider "databricks" {
  alias = "dev"    # Authenticate using preferred method as described in Databricks provider
}

provider "databricks" {
  alias = "staging"     # Authenticate using preferred method as described in Databricks provider
}

provider "databricks" {
  alias = "prod"     # Authenticate using preferred method as described in Databricks provider
}

module "mlops_azure_infrastructure_with_sp_linking" {
  source = "databricks/mlops-azure-infrastructure-with-sp-linking/databricks"
  providers = {
    databricks.dev = databricks.dev
    databricks.staging = databricks.staging
    databricks.prod = databricks.prod
  }
  staging_workspace_id          = "123456789"
  prod_workspace_id             = "987654321"
  azure_staging_client_id       = "k9l8m7n6o5-e5f6-g7h8-i9j0-a1b2c3d4p4"
  azure_staging_aad_token       = var.azure_staging_aad_token     # This value is sensitive.
  azure_prod_client_id          = "k9l8m7n6p4-e5f6-g7h8-i9j0-a1b2c3d4o5"
  azure_prod_aad_token          = var.azure_prod_aad_token     # This value is sensitive.
  additional_token_usage_groups = ["users"]     # This field is optional.
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
|staging_workspace_id|Workspace ID of the staging workspace ([can be often found in the URL](https://docs.microsoft.com/en-us/azure/databricks/workspace/workspace-details#--workspace-instance-names-urls-and-ids)) used for remote model registry setup.|string|N/A|yes|
|prod_workspace_id|Workspace ID of the prod workspace ([can be often found in the URL](https://docs.microsoft.com/en-us/azure/databricks/workspace/workspace-details#--workspace-instance-names-urls-and-ids)) used for remote model registry setup.|string|N/A|yes|
|azure_staging_client_id|The client ID of the AAD service principal in the staging workspace that will be used to READ the model registry from the dev workspace.|string|N/A|yes|
|azure_staging_aad_token|The AAD token of the service principal in the staging workspace. This will need to be manually refreshed once it expires (often within several minutes). NOTE: Only this or both `azure_staging_client_secret` & `azure_staging_tenant_id` need to be provided.|string|null|no|
|azure_staging_client_secret|The client secret of the AAD service principal in the staging workspace. NOTE: If `azure_staging_aad_token` is not provided, this and `azure_staging_tenant_id` must be provided to generate an AAD token.|string|null|no|
|azure_staging_tenant_id|The tenant ID of the AAD service principal in the staging workspace. NOTE: If `azure_staging_aad_token` is not provided, this and `azure_staging_client_secret` must be provided to generate an AAD token.|string|null|no|
|azure_prod_client_id|The client ID of the AAD service principal in the prod workspace that will be used to READ the model registry from the dev & staging workspaces.|string|N/A|yes|
|azure_prod_aad_token|The AAD token of the service principal in the prod workspace. This will need to be manually refreshed once it expires (often within several minutes). NOTE: Only this or both `azure_prod_client_secret` & `azure_prod_tenant_id` need to be provided.|string|null|no|
|azure_prod_client_secret|The client secret of the AAD service principal in the prod workspace. NOTE: If `azure_prod_aad_token` is not provided, this and `azure_prod_tenant_id` must be provided to generate an AAD token.|string|null|no|
|azure_prod_tenant_id|The tenant ID of the AAD service principal in the prod workspace. NOTE: If `azure_prod_aad_token` is not provided, this and `azure_prod_client_secret` must be provided to generate an AAD token.|string|null|no|
|additional_token_usage_groups|List of groups that should have token usage permissions in the staging and prod workspaces, along with the created service principal group (`mlops-service-principals`).|list(string)|\[\]|no|

## Outputs
| Name | Description | Type | Sensitive |
|------|-------------|------|---------|
|dev_secret_scope_name_for_staging|The name of the secret scope created in the dev workspace that is used for remote model registry access to the staging workspace.|string|no|
|dev_secret_scope_name_for_prod|The name of the secret scope created in the dev workspace that is used for remote model registry access to the prod workspace.|string|no|
|staging_secret_scope_name_for_prod|The name of the secret scope created in the staging workspace that is used for remote model registry access to the prod workspace.|string|no|
|dev_secret_scope_prefix_for_staging|The prefix used in the dev workspace secret scope for remote model registry access to the staging workspace.|string|no|
|dev_secret_scope_prefix_for_prod|The prefix used in the dev workspace secret scope for remote model registry access to the prod workspace.|string|no|
|staging_secret_scope_prefix_for_prod|The prefix used in the staging workspace secret scope for remote model registry access to the prod workspace.|string|no|

## Providers
| Name | Authentication | Use |
|------|-------------|----|
|databricks.dev|Provided by the user.|Generate all resources in the dev workspace.|
|databricks.staging|Provided by the user.|Generate all resources in the staging workspace.|
|databricks.prod|Provided by the user.|Generate all resources in the prod workspace.|
|databricks.staging_sp|Authenticated via host and generated AAD token for service principal.|Obtain service principal PAT.|
|databricks.prod_sp|Authenticated via host and generated AAD token for service principal.|Obtain service principal PAT.|

## Resources
| Name | Type |
|------|------|
|databricks_current_user.staging_user|data source|
|databricks_current_user.prod_user|data source|
|databricks_group.staging_sp_group|resource|
|databricks_permissions.staging_token_usage|resource|
|databricks_group.prod_sp_group|resource|
|databricks_permissions.prod_token_usage|resource|
|databricks_token.staging_sp_token|resource|
|databricks_token.prod_sp_token|resource|
|azure-link-service-principal.link_staging_sp|module|
|azure-link-service-principal.link_prod_sp|module|
|remote-model-registry.remote_model_registry_dev_to_staging|module|
|remote-model-registry.remote_model_registry_dev_to_prod|module|
|remote-model-registry.remote_model_registry_staging_to_prod|module|

## Known Issues
- AAD token generation occasionally fails with `"HTTP Error 400: Bad Request"` but the query is not actually invalid.
    - Solution: Re-run `terraform apply` and the error should disappear.