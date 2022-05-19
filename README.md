# demo-app-gw-env


This project provides a product demonstration of the Application Gateway, Azure Kubernetes Service and App Gateway Ingress Controller (AGIC) stack. Two applications are deployed to AKS where AGIC configures ingress access through App Gateway using the ARM API. Look for the following:

- End to End TLS (client, server and backend verification);
- Path based routing;
- Path based custom WAF policies.


# Getting Started

This repository provides the primitives needed to provision the required infrastructure in Microsoft Azure (bring-your-own-subscription), configure the cluster, and deploy the applications. A Makefile is also provided with a series of targets to automate these steps. In a product environment, each of these make targets would be analogous to a pipeline stage.

First, we need to format a `.env` file for some of our sensitive parameters. A template follows:


<!-- TODO:  clean up this .env file. Some of these aren't sensitive (so they don't need to be in the .env file.) and should be provided as a default or .tfvars. Additionally, the agic/install.sh script needs to be verified as we may use the TF_VAR_* variable. Move these too outputs if needed.-->
```
# This section holds configurations for the acme dns challenege
TF_VAR_registration_email=<>
TF_VAR_azure_client_id=<>
TF_VAR_azure_client_secret=<>
TF_VAR_azure_resource_group=<>
TF_VAR_azure_subscription_id="<>
TF_VAR_azure_tenant_id=<>
TF_VAR_azure_zone_name=<>
TF_VAR_dns_name=<>
# This section holds confogurations for the AKS Service Principal
TF_VAR_aks_service_principal_app_id=<>
TF_VAR_aks_service_principal_client_secret=<>
TF_VAR_aks_service_principal_object_id=<>
```

Gather the appropriate parameters and build the file. You will need at least one service principal for this.

```bash
az ad sp create-for-rbac --name app-gw-sp --role Contributor --scopes /subscriptions/<subscription_id>
```

<!-- TODO: You should provide a better explanation than this. Which variables from the output map to what variables in the env file? -->
Record these values in your `.env` file.

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
|`curl -v https://api.jacobnosal.com/app-a`| :white_check_mark:|
|`curl -v https://api.jacobnosal.com/app-b`| :white_check_mark:|
|`curl -v https://api.jacobnosal.com/app-a -h "X-CUSTOM-HEADER: this-is-something-suspicious"`| :x: |
|`curl -v https://api.jacobnosal.com/app-b/blocked-pages/aaa`| :x: |
|`curl -v https://api.jacobnosal.com/app-b/blocked-pages/bbb`| :x: |
|`curl -v https://api.jacobnosal.com/app-a --tlsv1.1`| :x: |
|`curl -v https://api.jacobnosal.com/app-a --tlsv1.2`| :white_check_mark:|
|`curl -v https://api.jacobnosal.com/app-b --tlsv1.2 --tls-max 1.2`| :white_check_mark: |
|`curl -v https://api.jacobnosal.com/app-a --tlsv1.3`| :white_check_mark: |