variable "tfe_org_token" {
  type = string
  description = "(Required) Terraform Cloud Organization Token"
  
  sensitive = true
}

variable "oci_tenancy_id" {
  type = string
  description = "(Required) Tenancy OCID"
}

variable "oci_user_id" {
  type = string
  description = "(Required) Oracle User OCID"
}

variable "oci_private_key" {
  type = string
  description = "(Required) Oracle User PEM private key"
  
  sensitive = true
}

variable "oci_key_fingerprint" {
  type = string
  description = "(Required) Private key fingerprint"
}

variable "oci_region_name" {
  type = string
  description = "(Required) OCI region name"
}
