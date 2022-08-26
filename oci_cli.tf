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
    test_oke_endpoint = local.oke_test_endpoint
    
    kubecurl = "curl --insecure --header 'Authorization: Bearer ${local.oke_test_token}' --header 'Content-Type: application/json'"
    
    kube_serviceaccount = jsonencode({
      apiVersion = "v1"
      kind = "ServiceAccount"
      metadata = {
        name = local.terraform_user_name
      }
    })
    
    kube_binding = jsonencode({
      apiVersion = "rbac.authorization.k8s.io/v1"
      kind = "ClusterRoleBinding"
      
      metadata = {
        name = "${local.terraform_user_name}-cluster-admin"
      }
      
      roleRef = {
        kind = "ClusterRole"
        apiGroup = "rbac.authorization.k8s.io"
        name = "cluster-admin"
      }
      
      subjects = [{
        kind = "ServiceAccount"
        namespace = local.terraform_user_namespace
        name = local.terraform_user_name
      }]
    })
    
    kube_secret = jsonencode({
      apiVersion = "v1"
      kind = "Secret"
      
      metadata = {
        name = "${local.terraform_user_name}-token"
        annotations = {
          "kubernetes.io/service-account.name" = local.terraform_user_name
        }
      }
      
      type = "kubernetes.io/service-account-token"
    })
  }
  
  provisioner "local-exec" {
    command = "${self.triggers.kubecurl} -X POST '${self.triggers.test_oke_endpoint}/api/v1/namespaces/${local.terraform_user_namespace}/serviceaccounts' --data '${self.triggers.kube_serviceaccount}'"
  }
  
  provisioner "local-exec" {
    command = "${self.triggers.kubecurl} -X POST '${self.triggers.test_oke_endpoint}/apis/rbac.authorization.k8s.io/v1/clusterrolebindings' --data '${self.triggers.kube_binding}'"
  }
  
  provisioner "local-exec" {
    command = "${self.triggers.kubecurl} -X POST '${self.triggers.test_oke_endpoint}/api/v1/namespaces/${local.terraform_user_namespace}/secrets' --data '${self.triggers.kube_secret}'"
  }
  
  provisioner "local-exec" {
    command = "${self.triggers.kubecurl} -X GET '${self.triggers.test_oke_endpoint}/api/v1/namespaces/${local.terraform_user_namespace}/secrets/${self.triggers.kube_secret.metadata.name}'"
  }
}
