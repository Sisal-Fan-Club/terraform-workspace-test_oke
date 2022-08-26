output "test_oke" {
  value = local.test_oke
  
  sensitive = true
}

output "terraform_sa" {
  value = local.terraform_secret
  
  sensitive = true
}
