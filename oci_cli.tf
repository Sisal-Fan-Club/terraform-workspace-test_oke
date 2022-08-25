locals {
  oke_test_token = module.oci_cli.oci_cli_command_outputs.generate_token.status.token
  oke_test_kubeconfig = yamldecode(data.oci_containerengine_cluster_kube_config.test_oke_kubeconfig.content)
  oke_test_cert_authority = base64decode(local.oke_test_kubeconfig.clusters[0].cluster.certificate-authority-data)
  oke_test_endpoint = local.oke_test_kubeconfig.clusters[0].cluster.server 
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

data "oci_containerengine_cluster_kube_config" "test_oke_kubeconfig" {
  cluster_id = local.test_oke.id
}
