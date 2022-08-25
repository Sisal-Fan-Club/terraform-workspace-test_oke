# Terraform global configuration
terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
      version = ">= 4"
    }
    
    tfe = {
      version = "~> 0.35"
    }
    
  }
}

# Terraform Cloud organizational provider
provider "tfe" {
  token = var.tfe_org_token
}

# OCI regional provider
provider "oci" {
  tenancy_ocid = var.oci_tenancy_id
  user_ocid = var.oci_user_id
  private_key = var.oci_private_key
  fingerprint = var.oci_key_fingerprint
  
  region = var.oci_region_name
}

# Find home region
data "oci_identity_tenancy" "oci_tenancy" {
    tenancy_id = var.oci_tenancy_id
}

data "oci_identity_regions" "home" {
  filter {
    name = "key"
    values = [data.oci_identity_tenancy.oci_tenancy.home_region_key]
  }
}

# OCI home provider
provider "oci" {
  alias = "home"
  
  tenancy_ocid = var.oci_tenancy_id
  user_ocid = var.oci_user_id
  private_key = var.oci_private_key
  fingerprint = var.oci_key_fingerprint
  
  region = data.oci_identity_regions.home.regions[0].name
}
