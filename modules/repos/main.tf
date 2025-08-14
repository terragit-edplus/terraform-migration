resource "github_repository" "repos" {
  for_each = { for r in var.repos : r.name => r }

  name        = each.value.name
  description = each.value.description
  visibility  = each.value.visibility
}