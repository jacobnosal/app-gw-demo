# demo-app-gw-env


This project provides a product demonstration of the Application Gateway, Azure Kubernetes Service and App Gateway Ingress Controller (AGIC) stack. Two applications are deployed to AKS where AGIC configures ingress access through App Gateway using the ARM API. Look for the following:

- End to End TLS (client, server and backend verification);
- Path based routing;
- Path based custom WAF policies.


# Getting Started

This repository provides the primitives needed to provision the required infrastructure in Microsoft Azure (bring-your-own-subscription), configure the cluster, and deploy the applications. A Makefile is also provided with a series of targets to automate these steps. In a product environment, each of these make targets would be analogous to a pipeline stage.

First, we need to format a `.env` file for some of our sensitive parameters. A template follows:


```
TF_VAR_azure_client_secret=<>
TF_VAR_aks_service_principal_client_secret=<>
```

Gather the appropriate parameters and build the file. You will need at least one service principal for this.

```bash
az ad sp create-for-rbac --name app-gw-sp --role Contributor --scopes /subscriptions/<subscription_id>
```

```bash
az ad sp list --display-name app-gw-sp --query "[].{\"Object ID\":objectId}" --output table
```

Record these values in your `.env` file with the following mappings:
- Set `TF_VAR_azure_client_secret` and `TF_VAR_aks_service_principal_client_secret` in `.env` to the password value returned.
- Set `azure_client_id` and `aks_service_principal_app_id` in `demo.tfvars` to the appId field returned.
- Set `azure_tenant_id` in `demo.tfvars` to the tenant field returned.
- Set `aks_service_principal_object_id` to the returned Object ID field.
- Set `azure_dns_resource_group` to the name of the esource group that holds the DNS Zone.
- Set `azure_dns_zone_name` to the DNS Zone name.
- Set `domain_name` to the domain contained in the DNS zone.
- Set `registration_email` to a valid email. You will be contacted at this email before the certificate expires.

We are now ready to build the Azure resources using Terraform.

```bash
make build
```

Once this is completed, deploy `cert-manager` + ClusterIssuer, `agic` and some necessary CRDs.


```bash
make agic
```

Now we can install the applications:


```bash
make services
```

Give the services, ingresses and Lets Encrypt certificates time to generate (~30s, depending on the speed of the DNS challenge for ACME certificate request) and then issue the following command to deploy the pods.


```bash
make pods
```


Open your browser and verify that the endpoints work:
- https://api.jacobnosal.com/app-a
- https://api.jacobnosal.com/app-b


# Environment Walkthrough


The AKS cluster is hosting two applications: `app-a` and `app-b`. App Gateway exposes these using path based routing as `api.jacobnosal.com/{app-a,app-b}` and applies a rewrite rule set to forward traffic to the appropriate services and pods with the `/{app-a,app-b}` prefix removed.

Annotations on the ingress resource apply a custom WAF policy to all paths contained in that resource. As path based routing implies each application is exposed under a prefix to the URL path, we can apply a custom WAF policy to each application. 


## SSL Policy


The Application Gateway is configured with a default SSL Policy to all incoming requests. Application Gateway Ingress Controller does not support the conifguration of a per-ingress SSL Profile but Application Gateway does. This [issue](https://github.com/Azure/application-gateway-kubernetes-ingress/issues/773) tracks a feature parity request between App gateway and AGIC. Predefined policies are explained [here](https://docs.microsoft.com/en-us/azure/application-gateway/application-gateway-ssl-policy-overview).


```
ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101S"
}
```


## WAF Policies

Each Azure WAF Policy allows for the configuration of custom rules in addition a core rule set. WAF Policy configurations are as follows:

- `app-a-waf-policy`
    - OWASP Ruleset v3.1
    - Match X-CUSTOM-HEADER contains 'something-suspicious' => **BLOCK**
- `app-b-waf-policy`
    - OWASP Ruleset v3.1
    - Match RequestUri contains '/blocked-page', '/blocked-pages/*' => **BLOCK**

<!-- TODO: Add reason and discussion of custom WAF policies. -->
| command | result | reason |
|:---|---|---|
|`curl -v https://api.jacobnosal.com/app-a`| :white_check_mark:| The request does not trigger a block due to headers |
|`curl -v https://api.jacobnosal.com/app-b`| :white_check_mark:| The request does not trigger a block due to routes |
|`curl -v https://api.jacobnosal.com/app-a -H "X-CUSTOM-HEADER: this-is-something-suspicious"`| :x: | The `app-a-waf-policy` matches `RequestHeaders/X-CUSTOM-HEADER` against `something-suspicious` with the `contains` operator |
|`curl -v https://api.jacobnosal.com/app-b -H "X-CUSTOM-HEADER: this-is-something-suspicious"`| :x: | The `app-b-waf-policy` does not block this header value |
|`curl -v https://api.jacobnosal.com/app-a/blocked-pages/aaa`| :white_check_mark: | The `app-a-waf-policy` does not block this route |
|`curl -v https://api.jacobnosal.com/app-b/blocked-page`| :x: | The URL matches against the `/blocked-page` value with the `contains` operator|
|`curl -v https://api.jacobnosal.com/app-b/blocked-pages/bbb`| :x: | The URL matches against the `/blocked-page` value with the `contains` operator |
|`curl -v https://api.jacobnosal.com/app-a --tlsv1.1 --tls-max 1.1`| :x: | TLS v1.1 is not an allowed TLS version|
|`curl -v https://api.jacobnosal.com/app-a --tlsv1.2 --tls-max 1.2`| :white_check_mark: | TLS v1.2 is allowed by SSL Policy |
|`curl -v https://api.jacobnosal.com/app-a --tlsv1.3`| :white_check_mark: | TLS v1.3 is allowed by SSL Policy |


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.26.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_waf-policies"></a> [waf-policies](#module\_waf-policies) | ./waf_policy | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_application_gateway.network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway) | resource |
| [azurerm_dns_a_record.api_jacobnosal_com](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_a_record) | resource |
| [azurerm_kubernetes_cluster.k8s](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_public_ip.pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_virtual_network.test](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subnet.appgwsubnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_subnet.kubesubnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_user_assigned_identity.app-gw-id](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/user_assigned_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aks_agent_count"></a> [aks\_agent\_count](#input\_aks\_agent\_count) | The number of agent nodes for the cluster. | `number` | `3` | no |
| <a name="input_aks_agent_os_disk_size"></a> [aks\_agent\_os\_disk\_size](#input\_aks\_agent\_os\_disk\_size) | Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 applies the default disk size for that agentVMSize. | `number` | `40` | no |
| <a name="input_aks_agent_vm_size"></a> [aks\_agent\_vm\_size](#input\_aks\_agent\_vm\_size) | VM size | `string` | `"Standard_D3_v2"` | no |
| <a name="input_aks_dns_prefix"></a> [aks\_dns\_prefix](#input\_aks\_dns\_prefix) | Optional DNS prefix to use with hosted Kubernetes API server FQDN. | `string` | `"aks"` | no |
| <a name="input_aks_dns_service_ip"></a> [aks\_dns\_service\_ip](#input\_aks\_dns\_service\_ip) | DNS server IP address | `string` | `"10.0.0.10"` | no |
| <a name="input_aks_docker_bridge_cidr"></a> [aks\_docker\_bridge\_cidr](#input\_aks\_docker\_bridge\_cidr) | CIDR notation IP for Docker bridge. | `string` | `"172.17.0.1/16"` | no |
| <a name="input_aks_enable_rbac"></a> [aks\_enable\_rbac](#input\_aks\_enable\_rbac) | Enable RBAC on the AKS cluster. Defaults to false. | `string` | `"false"` | no |
| <a name="input_aks_name"></a> [aks\_name](#input\_aks\_name) | AKS cluster name | `string` | `"aks-cluster1"` | no |
| <a name="input_aks_service_cidr"></a> [aks\_service\_cidr](#input\_aks\_service\_cidr) | CIDR notation IP range from which to assign service cluster IPs | `string` | `"10.0.0.0/16"` | no |
| <a name="input_aks_service_principal_app_id"></a> [aks\_service\_principal\_app\_id](#input\_aks\_service\_principal\_app\_id) | Application ID/Client ID  of the service principal. Used by AKS to manage AKS related resources on Azure like vms, subnets. | `any` | n/a | yes |
| <a name="input_aks_service_principal_client_secret"></a> [aks\_service\_principal\_client\_secret](#input\_aks\_service\_principal\_client\_secret) | Secret of the service principal. Used by AKS to manage Azure. | `any` | n/a | yes |
| <a name="input_aks_service_principal_object_id"></a> [aks\_service\_principal\_object\_id](#input\_aks\_service\_principal\_object\_id) | Object ID of the service principal. | `any` | n/a | yes |
| <a name="input_aks_subnet_address_prefix"></a> [aks\_subnet\_address\_prefix](#input\_aks\_subnet\_address\_prefix) | Subnet address prefix. | `string` | `"192.168.0.0/24"` | no |
| <a name="input_aks_subnet_name"></a> [aks\_subnet\_name](#input\_aks\_subnet\_name) | Subnet Name. | `string` | `"kubesubnet"` | no |
| <a name="input_app_gateway_name"></a> [app\_gateway\_name](#input\_app\_gateway\_name) | Name of the Application Gateway | `string` | `"ApplicationGateway1"` | no |
| <a name="input_app_gateway_sku"></a> [app\_gateway\_sku](#input\_app\_gateway\_sku) | Name of the Application Gateway SKU | `string` | `"WAF_v2"` | no |
| <a name="input_app_gateway_subnet_address_prefix"></a> [app\_gateway\_subnet\_address\_prefix](#input\_app\_gateway\_subnet\_address\_prefix) | Subnet server IP address. | `string` | `"192.168.1.0/24"` | no |
| <a name="input_app_gateway_tier"></a> [app\_gateway\_tier](#input\_app\_gateway\_tier) | Tier of the Application Gateway tier | `string` | `"WAF_v2"` | no |
| <a name="input_azure_client_id"></a> [azure\_client\_id](#input\_azure\_client\_id) | n/a | `any` | n/a | yes |
| <a name="input_azure_client_secret"></a> [azure\_client\_secret](#input\_azure\_client\_secret) | n/a | `any` | n/a | yes |
| <a name="input_azure_dns_resource_group"></a> [azure\_dns\_resource\_group](#input\_azure\_dns\_resource\_group) | n/a | `any` | n/a | yes |
| <a name="input_azure_dns_zone_name"></a> [azure\_dns\_zone\_name](#input\_azure\_dns\_zone\_name) | n/a | `any` | n/a | yes |
| <a name="input_azure_subscription_id"></a> [azure\_subscription\_id](#input\_azure\_subscription\_id) | n/a | `any` | n/a | yes |
| <a name="input_azure_tenant_id"></a> [azure\_tenant\_id](#input\_azure\_tenant\_id) | n/a | `any` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | DNS name of the certificate subject. | `any` | n/a | yes |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version | `string` | `"1.11.5"` | no |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | `"eastus"` | no |
| <a name="input_managed_identity_name"></a> [managed\_identity\_name](#input\_managed\_identity\_name) | Name of the managed identity. | `string` | `"ApplicationGatewayIdentity"` | no |
| <a name="input_public_ssh_key_path"></a> [public\_ssh\_key\_path](#input\_public\_ssh\_key\_path) | Public key path for SSH. | `string` | `"~/.ssh/id_rsa.pub"` | no |
| <a name="input_registration_email"></a> [registration\_email](#input\_registration\_email) | Email to register with ACME for this cert. | `any` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | n/a | `string` | `"rg-app-gw-demo"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map` | <pre>{<br>  "environment": "demo"<br>}</pre> | no |
| <a name="input_virtual_network_address_prefix"></a> [virtual\_network\_address\_prefix](#input\_virtual\_network\_address\_prefix) | VNET address prefix | `string` | `"192.168.0.0/16"` | no |
| <a name="input_virtual_network_name"></a> [virtual\_network\_name](#input\_virtual\_network\_name) | Virtual network name | `string` | `"aksVirtualNetwork"` | no |
| <a name="input_vm_user_name"></a> [vm\_user\_name](#input\_vm\_user\_name) | User name for the VM | `string` | `"vmuser1"` | no |
| <a name="input_waf_resource_group"></a> [waf\_resource\_group](#input\_waf\_resource\_group) | n/a | `string` | `"rg-waf-policies"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aks_rbac_enabled"></a> [aks\_rbac\_enabled](#output\_aks\_rbac\_enabled) | n/a |
| <a name="output_application_domain_name"></a> [application\_domain\_name](#output\_application\_domain\_name) | n/a |
| <a name="output_application_gateway_name"></a> [application\_gateway\_name](#output\_application\_gateway\_name) | n/a |
| <a name="output_application_ip_address"></a> [application\_ip\_address](#output\_application\_ip\_address) | n/a |
| <a name="output_client_certificate"></a> [client\_certificate](#output\_client\_certificate) | n/a |
| <a name="output_client_id"></a> [client\_id](#output\_client\_id) | n/a |
| <a name="output_client_key"></a> [client\_key](#output\_client\_key) | n/a |
| <a name="output_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#output\_cluster\_ca\_certificate) | n/a |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | n/a |
| <a name="output_cluster_password"></a> [cluster\_password](#output\_cluster\_password) | n/a |
| <a name="output_cluster_username"></a> [cluster\_username](#output\_cluster\_username) | n/a |
| <a name="output_dns_resource_group_name"></a> [dns\_resource\_group\_name](#output\_dns\_resource\_group\_name) | n/a |
| <a name="output_dns_zone_name"></a> [dns\_zone\_name](#output\_dns\_zone\_name) | n/a |
| <a name="output_host"></a> [host](#output\_host) | n/a |
| <a name="output_kube_config"></a> [kube\_config](#output\_kube\_config) | n/a |
| <a name="output_registration_email"></a> [registration\_email](#output\_registration\_email) | n/a |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | n/a |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | n/a |
| <a name="output_tenant_id"></a> [tenant\_id](#output\_tenant\_id) | n/a |
<!-- END_TF_DOCS -->