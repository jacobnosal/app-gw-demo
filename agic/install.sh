#!/bin/bash

set -x
set -o errexit

root_dir=${PWD%/*}
export subscription_id=$(terraform output -raw -state="$root_dir/terraform.tfstate" subscription_id)
export app_gateway_name=$(terraform output -raw -state="$root_dir/terraform.tfstate" application_gateway_name)
export identity_resource_id=$(terraform output -raw -state="$root_dir/terraform.tfstate" identity_resource_id)
export identity_client_id=$(terraform output -raw -state="$root_dir/terraform.tfstate" identity_client_id)
export resource_group_name=$(terraform output -raw -state="$root_dir/terraform.tfstate" resource_group_name)
export aks_cluster_name=$(terraform output -raw -state="$root_dir/terraform.tfstate" cluster_name)
export aks_cluster_rbac_enabled=$(terraform output -raw -state="$root_dir/terraform.tfstate" aks_rbac_enabled)

yq -i '.appgw.subscriptionId = strenv(subscription_id)' helm-config.yaml
yq -i '.appgw.resourceGroup = strenv(resource_group_name)' helm-config.yaml
yq -i '.appgw.name = strenv(app_gateway_name)' helm-config.yaml
yq -i '.armAuth.identityResourceID = strenv(identity_resource_id)' helm-config.yaml
yq -i '.armAuth.identityClientID = strenv(identity_client_id)' helm-config.yaml

cat helm-config.yaml

az aks get-credentials --name $aks_cluster_name --resource-group $resource_group_name --overwrite-existing

if [ $aks_cluster_rbac_enabled == "true" ]; then
    kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment-rbac.yaml
else
    kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment.yaml
fi

az role assignment create --role "Managed Identity Operator" --assignee $identity_client_id --scope $identity_resource_id

helm repo add application-gateway-kubernetes-ingress https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/
helm repo update
helm install -f helm-config.yaml application-gateway-kubernetes-ingress/ingress-azure --generate-name

unset subscription_id
unset app_gateway_name
unset identity_resource_id
unset identity_client_id
unset resource_group_name
unset aks_cluster_name
unset aks_cluster_rbac_enabled
