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


The Application Gateway is configured with a default SSL Policy to all incoming requests. Application Gateway Ingress Controller does not support the conifguration of a per-ingress SSL Profile but Application Gateway does. This [issue](https://github.com/Azure/application-gateway-kubernetes-ingress/issues/773) tracks a feature parity request between App gateway and AGIC.

```
ssl_policy {
    policy_type = "Custom"
    min_protocol_version = "TLSv1_2"
    disabled_protocols = ["TLSv1_0", "TLSv1_1"]
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
|`curl -v https://api.jacobnosal.com/app-a`| :white_check_mark:| |
|`curl -v https://api.jacobnosal.com/app-b`| :white_check_mark:| |
|`curl -v https://api.jacobnosal.com/app-a -h "X-CUSTOM-HEADER: this-is-something-suspicious"`| :x: | |
|`curl -v https://api.jacobnosal.com/app-b/blocked-pages/aaa`| :x: | |
|`curl -v https://api.jacobnosal.com/app-b/blocked-pages/bbb`| :x: | |
|`curl -v https://api.jacobnosal.com/app-a --tlsv1.1`| :x: | |
|`curl -v https://api.jacobnosal.com/app-a --tlsv1.2`| :white_check_mark: | |
|`curl -v https://api.jacobnosal.com/app-b --tlsv1.2 --tls-max 1.2`| :white_check_mark: | |
|`curl -v https://api.jacobnosal.com/app-a --tlsv1.3`| :white_check_mark: | |

