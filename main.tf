provider "github" {
    owner = var.github_organization
    app_auth {}
}

locals {
  repos              = csvdecode(file("${path.module}/csv/repos.csv"))
}

module "repos" {
  source = "./modules/repos"
  repos  = local.repos
}