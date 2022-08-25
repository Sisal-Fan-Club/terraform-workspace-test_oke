module "servers" {
  source = "github.com/Terraform-Modules-Lib/terraform-oci-cli"
  
  oci_tenancy_id = var.oci_tenancy_id
  oci_user_id = var.oci_user_id
  oci_private_key = var.oci_private_key
  oci_key_fingerprint = var.oci_key_fingerprint
  oci_region_name = var.oci_region_name
  
  commands = {
    generate_token = "ce cluster generate-token --cluster-id ${local.test_oke} --region ${var.oci_region_name}"
  }
}
