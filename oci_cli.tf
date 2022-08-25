locals {
  oke_token = module.oci_cli.oci_cli_command_outputs.generate_token.status.token
}

module "oci_cli" {
  source = "github.com/Terraform-Modules-Lib/terraform-oci-cli"
  
  oci_tenancy_id = var.oci_tenancy_id
  oci_user_id = var.oci_user_id
  oci_private_key = var.oci_private_key
  oci_key_fingerprint = var.oci_key_fingerprint
  oci_region_name = var.oci_region_name
  
  commands = {
    generate_token = "ce cluster generate-token --cluster-id ${local.test_oke.id} --region ${var.oci_region_name}"
  }
}
  
output "token" {
  value = module.oci_cli.oci_cli_command_outputs
}
  
provider "kubernetes" {
  host = "https://${local.test_oke.endpoints[0].public_endpoint}"
  token = local.oke_token
}
  
resource "kubernetes_namespace" "example" {
  metadata {
    name = "my-first-namespace"
  }
}
