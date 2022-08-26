locals {
  oke_test_token = module.oci_cli.oci_cli_command_outputs.generate_token.status.token
    
  oke_test_kubeconfig = yamldecode(data.oci_containerengine_cluster_kube_config.test_oke_kubeconfig.content)
  oke_test_cert_authority = base64decode(local.oke_test_kubeconfig.clusters[0].cluster.certificate-authority-data)
  oke_test_cert_authority_file = local_file.test_oke_ca
  oke_test_endpoint = local.oke_test_kubeconfig.clusters[0].cluster.server
  
  terraform_user_name = "terraform-cloud"
  terraform_user_namespace = "kube-system"
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

resource "local_file" "test_oke_ca" {
  filename = "${path.module}/test_oke_ca.crt"
  file_permission = "0666"
  
  content = local.oke_test_token
}

resource "null_resource" "create_terraform_user" {
  triggers = {
    
    cmd_create_service_account = <<-EOC
      curl \
        -X POST \
        '${local.oke_test_endpoint}/api/v1/namespaces/${local.terraform_user_namespace}/serviceaccounts' \
        --cacert ${local.oke_test_cert_authority_file.filename} \
        --header 'Authorization: Bearer ${local.oke_test_token}' \
        --header 'Content-Type: application/json' \
        --data '
          {
            "apiVersion": "v1",
            "kind": "ServiceAccount",
            "metadata": {
              "name": "${local.terraform_user_name}"
            }
          }
        '
    EOC
    
    
  }
  
  provisioner "local-exec" {
    command = "${self.triggers.cmd_create_service_account}"
  }
}
