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

  depends_on = [ github_repository.repos ]
}

locals {
  default_keys = toset(flatten([
    for repo, _ in github_repository.repos : [
      for b in local.default_branches : "${repo}:${b}"
    ]
  ]))

  custom_branches_filtered = {
    for b in var.branches :
    "${b.repo}:${b.branch}" => b
    if !contains(local.default_keys, "${b.repo}:${b.branch}")
  }

}

resource "github_branch" "custom" {
  for_each = local.custom_branches_filtered

  repository = each.value.repo
  branch     = each.value.branch

  lifecycle {
  precondition {
    condition     = contains(keys(github_repository.repos), each.value.repo)
    error_message = "branches.csv references repo '${each.value.repo}' which is not managed by Terraform."
    }
  }

  depends_on = [ github_repository.repos ]
}

resource "github_repository_collaborators" "users" {

  for_each  = { for p in var.user_permissions : "${p.repo}:${p.user}" => p }

  repository = each.value.repo
  user{
    username   = each.value.user
    permission = each.value.permission
  }

  depends_on = [ github_repository.repos ]
  
}

resource "github_repository_collaborators" "teams" {

  for_each  = { for p in var.team_permissions : "${p.repo}:${p.team}" => p }

  repository = each.value.repo

  team{
    team_id    = each.value.team
    permission = each.value.permission
  }
  
  depends_on = [ github_repository.repos ]
}

resource "github_repository_file" "codeowners"{
  for_each = local.custom_branches_filtered

  repository = each.value.repo
  branch     = each.value.branch

  file       = ".github/CODEOWNERS"
  content    = file("${path.module}/CODEOWNERS.tmpl")
  commit_message = "Add CODEOWNERS file to ${each.value.branch} branch"
  overwrite_on_create = true

  depends_on = [ github_branch.custom ]
}

resource "github_branch_protection_v3" "protection" {
  for_each = { for b in var.branches : "${b.repo}:${b.branch}" => b }
  repository = each.value.repo
  branch     = each.value.branch
  required_pull_request_reviews {
    require_code_owner_reviews = each.value.codeOwnerReviewRequired
    required_approving_review_count = each.value.minPRCount
  }
  restrictions {
    users = length(trimspace(each.value.users)) > 0 ? split(",", each.value.users) : []
    teams = length(trimspace(each.value.teams)) > 0 ? split(",", each.value.teams) : []
  }
   depends_on = [github_branch.default, github_branch.custom ]
}