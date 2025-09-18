provider "github" {
    owner = var.github_organization
    app_auth {
        id              = var.app_id
        installation_id = var.app_installation_id
        pem_file        = var.app_pem_file
    }
}

locals {
  config           = jsondecode(file(var.config_path))
  repos              = local.config.repos
  members            = local.config.members
  teams              = local.config.teams
  team_members       = local.config.team_members
  branches           = local.config.branches
  user_permissions   = local.config.user_permissions
  team_permissions   = local.config.team_permissions
  administrators              = local.config.administrators
  codeowners_rules  = local.config.codeowners_rules
}

module "members" {
  source  = "./modules/org"
  members = local.members

}

module "teams" {
  source = "./modules/teams"
  teams  = local.teams
  team_members = local.team_members
}

module "repos" {
  source = "./modules/repos"
  repos  = local.repos
  branches = local.branches
  user_permissions = local.user_permissions
  team_permissions = local.team_permissions
  administrators = local.administrators
  codeowners_rules = local.codeowners_rules
}


