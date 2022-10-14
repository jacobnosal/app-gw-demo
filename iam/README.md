<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.27.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.app-gw-id-Contributor-app-gw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.app-gw-id-Reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.sp-Managed-Identity-Operator-app-gw-id](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.sp-Network-Contributor-kubesubnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_user_assigned_identity.app-gw-id](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aks_service_principal_app_id"></a> [aks\_service\_principal\_app\_id](#input\_aks\_service\_principal\_app\_id) | Application ID/Client ID  of the service principal. Used by AKS to manage AKS related resources on Azure like vms, subnets. | `any` | n/a | yes |
| <a name="input_aks_service_principal_client_secret"></a> [aks\_service\_principal\_client\_secret](#input\_aks\_service\_principal\_client\_secret) | Secret of the service principal. Used by AKS to manage Azure. | `any` | n/a | yes |
| <a name="input_aks_service_principal_object_id"></a> [aks\_service\_principal\_object\_id](#input\_aks\_service\_principal\_object\_id) | Object ID of the service principal. | `any` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | `"eastus"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | n/a | `string` | `"rg-app-gw-demo"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map` | <pre>{<br>  "environment": "demo"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_client_id"></a> [client\_id](#output\_client\_id) | n/a |
| <a name="output_identity_client_id"></a> [identity\_client\_id](#output\_identity\_client\_id) | n/a |
| <a name="output_identity_resource_id"></a> [identity\_resource\_id](#output\_identity\_resource\_id) | n/a |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | n/a |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | n/a |
<!-- END_TF_DOCS -->