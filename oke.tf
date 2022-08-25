locals {
  test_compartment = local.tfe_workspace_outputs.test_compartment.test_compartment
  
  vcn = local.tfe_workspace_outputs.vcn.vcn
  app_subnet = local.tfe_workspace_outputs.test_subnets.app_subnet
  dmz_subnet = local.tfe_workspace_outputs.test_subnets.dmz_subnet
  
  test_oke = oci_containerengine_cluster.test_oke
}

resource "oci_containerengine_cluster" "test_oke" {
  compartment_id = local.test_compartment.id
  vcn_id = local.vcn.id
  
  name = "oke-${local.test_compartment.name}"
  kubernetes_version = "v1.24.1"
  
  endpoint_config {
    subnet_id = local.dmz_subnet.id
    is_public_ip_enabled = true
  }
  
  options {
    service_lb_subnet_ids = [
      local.dmz_subnet.id
    ]
    service_lb_config {
      freeform_tags = merge({
      }, local.dmz_subnet.freeform_tags, local.vcn.freeform_tags, local.test_compartment.freeform_tags)
    }
  }
  
  freeform_tags = merge({
  }, local.test_compartment.freeform_tags)
}
