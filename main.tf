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
}

module "repos" {
  source = "./modules/repos"
  repos  = local.repos
}

module "members" {
  source  = "./modules/org"
  members = local.members
}
