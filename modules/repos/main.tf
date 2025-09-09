resource "github_repository" "repos" {
  for_each = { for r in var.repos : r.name => r }

  name        = each.value.name
  description = each.value.description
  visibility  = each.value.visibility

  auto_init = true
}

locals {
  default_branches = ["development", "qa", "staging", "production"]

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

  admin_teams = setproduct(var.repos.*.name, var.administrators.*.team)

  environments = setproduct(var.repos.*.name, local.default_branches)

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

resource "github_repository_collaborator" "users" {

  for_each  = { for p in var.user_permissions : "${p.repo}:${p.user}" => p }

  repository = each.value.repo
  username   = each.value.user
  permission = each.value.permission
  

  depends_on = [ github_repository.repos ]
  
}

resource "github_team_repository" "teams" {

  for_each  = { for p in var.team_permissions : "${p.repo}:${p.team}" => p }

  repository = each.value.repo

  
  team_id    = each.value.team
  permission = each.value.permission
  
  depends_on = [ github_repository.repos ]
}

resource "github_team_repository" "default" {
  
  for_each    = { for at in local.admin_teams : "${at[0]}:${at[1]}" => at }
  repository = each.value[0]
  team_id    = each.value[1]
  permission = "admin"

}

locals {
  content = {
    for r in var.codeowners_rules :
    "${r.repo}:${r.branch}:${r.path}" => join("\n", concat(
      [
        "# ----------------------------------------------------------------------",
        "# DO NOT MODIFY THIS FILE DIRECTLY",
        "# This CODEOWNERS file is managed by Terraform",
        "# ----------------------------------------------------------------------"
      ],
      [
      for x in var.codeowners_rules :
      "${x.path} ${join(" ", concat(
        [for u in split(",", x.users) : "@${trimspace(u)}" if trimspace(u) != ""],
        [for t in split(",", x.teams) : "@terragit-edplus/${trimspace(t)}" if trimspace(t) != ""]
      ))}"
      if x.repo == r.repo && x.branch == r.branch
    ]
    ))
  }
}

resource "github_repository_file" "codeowners" {
  for_each    = local.content
  repository          = split(":", each.key)[0]
  branch              = split(":", each.key)[1]
  file                = ".github/CODEOWNERS"
  content             = each.value
  commit_message      = "Add CODEOWNERS"
  overwrite_on_create = true
  depends_on          = [github_branch.default, github_branch.custom]
}

resource "github_branch_protection_v3" "protection" {
  for_each = { for b in var.branches : "${b.repo}:${b.branch}" => b }
  repository = each.value.repo
  branch     = each.value.branch
  enforce_admins = true
  required_pull_request_reviews {
    require_code_owner_reviews = each.value.codeOwnerReviewRequired
    required_approving_review_count = each.value.minPRCount
  }
  restrictions {
    users = length(trimspace(each.value.users)) > 0 ? split(";", each.value.users) : []
    teams = length(trimspace(each.value.teams)) > 0 ? split(";", each.value.teams) : []
  }
   depends_on = [github_branch.default, github_branch.custom ]
}

resource "github_repository_environment" "envs" {
  for_each = {for env in local.environments : "$env[0]:$env[1]" => env}
  repository = each.value[0]
  environment       = each.value[1]
  deployment_branch_policy {
    protected_branches = false
    custom_branch_policies = false
  }
}

resource "github_repository_environment_deployment_policy" "env_policy" {
  for_each = {for env in local.environments : "$env[0]:$env[1]" => env}
  repository = each.value[0]
  environment = each.value[1]
  tag_pattern = each.value[1]
}