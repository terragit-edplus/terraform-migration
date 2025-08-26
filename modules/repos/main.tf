resource "github_repository" "repos" {
  for_each = { for r in var.repos : r.name => r }

  name        = each.value.name
  description = each.value.description
  visibility  = each.value.visibility

  auto_init = true
}

resource "github_branch" "development" {
  for_each = { for r in var.repos : r.name => r }

  repository = each.value.name
  branch     = "development"
}

resource "github_branch" "qa" {
  for_each = { for r in var.repos : r.name => r }

  repository = each.value.name
  branch     = "qa"
}

resource "github_branch" "staging" {
  for_each = { for r in var.repos : r.name => r }

  repository = each.value.name
  branch     = "staging"
}

resource "github_branch" "production" {
  for_each = { for r in var.repos : r.name => r }

  repository = each.value.name
  branch     = "production"
}

resource "github_branch" "custom" {
  for_each = { for b in var.branches : b.repo => b }

  repository = each.value.repo
  branch     = each.value.branch
}