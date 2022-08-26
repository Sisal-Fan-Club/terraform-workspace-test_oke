locals {
  terraform_user_name = "terraform-cloud"
  terraform_user_namespace = "kube-system"
  terraform_secret = jsondecode(data.local_sensitive_file.terraform_secret.content)
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
    kube_secret_file = "${path.module}/${local.terraform_user_name}-token.secret.json"
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
    command = "${self.triggers.kubecurl} -X GET '${self.triggers.test_oke_endpoint}/api/v1/namespaces/${local.terraform_user_namespace}/secrets/${local.terraform_user_name}-token' -o ${self.triggers.kube_secret_file}"
  }
}
  
data "local_sensitive_file" "terraform_secret" {
  filename = null_resource.create_terraform_user.triggers.kube_secret_file
}

