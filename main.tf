provider "github" {
  owner = var.github_organization
  app_auth {
    id              = var.app_id
    installation_id = var.app_installation_id
    pem_file        = var.app_pem_file
  }
}

locals {
  administrators   = csvdecode(file("data/admins.csv"))
  branches         = csvdecode(file("data/branches.csv"))
  codeowners_rules = csvdecode(file("data/codeowners_rules.csv"))
  environments     = csvdecode(file("data/environments.csv"))
  members          = csvdecode(file("data/members.csv"))
  repos            = csvdecode(file("data/repos.csv"))
  team_members     = csvdecode(file("data/team_members.csv"))
  team_permissions = csvdecode(file("data/team_repo_permissions.csv"))
  teams            = csvdecode(file("csv/teams.csv"))
  user_permissions = csvdecode(file("csv/user_permissions.csv"))
}

module "members" {
  source  = "./modules/org"
  members = local.members
}

module "teams" {
  source       = "./modules/teams"
  teams        = local.teams
  team_members = local.team_members
  depends_on   = [module.members]
}

module "repos" {
  source           = "./modules/repos"
  repos            = local.repos
  branches         = local.branches
  user_permissions = local.user_permissions
  team_permissions = local.team_permissions
  administrators   = local.administrators
  codeowners_rules = local.codeowners_rules
  environments     = local.environments
  depends_on       = [module.members, module.teams]
}


