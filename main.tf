provider "github" {
    owner = var.github_organization
    app_auth {
        id              = var.app_id
        installation_id = var.app_installation_id
        pem_file        = var.app_pem_file
    }
}

locals {
  repos              = csvdecode(file("${path.module}/csv/repos.csv"))
  members            = csvdecode(file("${path.module}/csv/members.csv"))
  teams              = csvdecode(file("${path.module}/csv/teams.csv"))
  team_members       = csvdecode(file("${path.module}/csv/team_members.csv"))
  branches           = csvdecode(file("${path.module}/csv/branches.csv"))
  user_permissions   = csvdecode(file("${path.module}/csv/user_repo_permissions.csv"))
  team_permissions   = csvdecode(file("${path.module}/csv/team_repo_permissions.csv"))
}

module "repos" {
  source = "./modules/repos"
  repos  = local.repos
  branches = local.branches
  user_permissions = local.user_permissions
  team_permissions = local.team_permissions
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
