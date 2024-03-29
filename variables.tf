# Args for terraform-acme-msftcerts
variable "registration_email" {
  description = "Email to register with ACME for this cert."
}

variable "domain_name" {
  description = "DNS name of the certificate subject."
}

variable "azure_client_id" {}
variable "azure_client_secret" {}
variable "azure_dns_resource_group" {}
variable "azure_subscription_id" {}
variable "azure_tenant_id" {}
variable "azure_dns_zone_name" {}

variable "waf_resource_group" {
  default = "rg-waf-policies"
}

variable "location" {
  default = "eastus"
}

variable "resource_group_name" {
  default = "gtw-rg-demo"
}

variable "tags" {
  default = {
    environment = "demo"
  }
}

variable "aks_service_principal_app_id" {
  description = "Application ID/Client ID  of the service principal. Used by AKS to manage AKS related resources on Azure like vms, subnets."
}

variable "aks_service_principal_client_secret" {
  description = "Secret of the service principal. Used by AKS to manage Azure."
}

variable "aks_service_principal_object_id" {
  description = "Object ID of the service principal."
}

variable "managed_identity_name" {
  description = "Name of the managed identity."
  default     = "iam-uai-demo"
}

variable "managed_identity_resource_group_name" {
  default = "iam-rg-demo"
}

variable "virtual_network_name" {
  description = "Virtual network name"
  default     = "aksVirtualNetwork"
}

variable "virtual_network_address_prefix" {
  description = "VNET address prefix"
  default     = "192.168.0.0/16"
}

variable "aks_subnet_name" {
  description = "Subnet Name."
  default     = "kubesubnet"
}

variable "aks_subnet_address_prefix" {
  description = "Subnet address prefix."
  default     = "192.168.0.0/24"
}

variable "app_gateway_subnet_address_prefix" {
  description = "Subnet server IP address."
  default     = "192.168.1.0/24"
}

variable "aks_name" {
  description = "AKS cluster name"
  default     = "aks-cluster1"
}
variable "aks_dns_prefix" {
  description = "Optional DNS prefix to use with hosted Kubernetes API server FQDN."
  default     = "aks"
}

variable "aks_agent_os_disk_size" {
  description = "Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 applies the default disk size for that agentVMSize."
  default     = 40
}

variable "aks_agent_count" {
  description = "The number of agent nodes for the cluster."
  default     = 3
}

variable "aks_agent_vm_size" {
  description = "VM size"
  default     = "Standard_D3_v2"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  default     = "1.11.5"
}

variable "aks_service_cidr" {
  description = "CIDR notation IP range from which to assign service cluster IPs"
  default     = "10.0.0.0/16"
}

variable "aks_dns_service_ip" {
  description = "DNS server IP address"
  default     = "10.0.0.10"
}

variable "aks_docker_bridge_cidr" {
  description = "CIDR notation IP for Docker bridge."
  default     = "172.17.0.1/16"
}

variable "aks_enable_rbac" {
  description = "Enable RBAC on the AKS cluster. Defaults to false."
  default     = "false"
}

variable "vm_user_name" {
  description = "User name for the VM"
  default     = "vmuser1"
}

variable "public_ssh_key_path" {
  description = "Public key path for SSH."
  default     = "~/.ssh/id_rsa.pub"
}

variable "app_gateway_name" {
  description = "Name of the Application Gateway"
  default     = "ApplicationGateway1"
}

variable "app_gateway_sku" {
  description = "Name of the Application Gateway SKU"
  default     = "WAF_v2"
}

variable "app_gateway_tier" {
  description = "Tier of the Application Gateway tier"
  default     = "WAF_v2"
}