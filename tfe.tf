locals {
  tfe_org = data.tfe_organization.org
  
  tfe_workspace_outputs = {
    for workspace_name, workspace_outputs in data.tfe_outputs.workspace_outputs :
        workspace_name => {
          for output_name, output_value in workspace_outputs.values :
              output_name => output_value
        }
  }
}

data "tfe_organization" "org" {
  name = "sisal-fan-club"
}

data "tfe_workspace_ids" "workspaces" {
  organization = local.tfe_org.name
  
  names = ["*"]
}

data "tfe_outputs" "workspace_outputs" {
  for_each = data.tfe_workspace_ids.workspaces.full_names
  
  organization = local.tfe_org.name
  workspace = each.key
}
