resource "github_repository" "repos" {
  for_each = { for r in var.repos : r.name => r }

  name        = each.value.name
  description = each.value.description
  visibility  = each.value.visibility

  auto_init = true
}

locals {
  default_branches = ["development", "qa", "staging", "production"]
}

resource "github_branch" "default" {
  for_each      = { for rb in flatten([
    for repo, _ in github_repository.repos : [
      for b in local.default_branches : {
        repo   = repo
        branch = b
      }
    ]
  ]) : "${rb.repo}:${rb.branch}" => rb }

  repository    = each.value.repo
  branch        = each.value.branch
  source_branch = "main"
}

resource "github_branch" "custom" {
  for_each = { for b in var.branches : b.repo => b }

  repository = each.value.repo
  branch     = each.value.branch

  lifecycle {
  precondition {
    condition     = contains(keys(github_repository.repos), each.value.repo)
    error_message = "branches.csv references repo '${each.value.repo}' which is not managed by Terraform."
    }
  }
}

resource "github_repository_collaborators" "users" {

  for_each = { for p in var.user_permissions : p.repo =>p }

  repository = each.value.repo
  user{
    username   = each.value.user
    permission = each.value.permission
  }
  
}

resource "github_repository_collaborators" "teams" {

  for_each = { for p in var.team_permissions : p.repo =>p }

  repository = each.value.repo
  
  team{
    team_id    = each.value.team
    permission = each.value.permission
  }
  
}