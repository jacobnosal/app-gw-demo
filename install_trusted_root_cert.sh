#!/bin/bash

set -x
set -o errexit

application_domain_name="api.jacobnosal.com"
app_gateway_name=$(terraform output -raw -state="terraform.tfstate" application_gateway_name)
resource_group_name=$(terraform output -raw -state="terraform.tfstate" resource_group_name)

az network application-gateway root-cert create \
        --cert-file "keys/$application_domain_name.trusted_root_cert.cer"  \
        --gateway-name $app_gateway_name \
        --name "$application_domain_name-trusted-root-cert" \
        --resource-group $resource_group_name