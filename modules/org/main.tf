resource "github_membership" "members" {
  for_each = { for m in var.members : m.username => m }

  username = each.value.username
  role     = each.value.role
}
