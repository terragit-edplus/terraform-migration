resource "github_team" "teams" {
  for_each = { for t in var.teams : t.name => t }

  name        = each.value.name
  description = each.value.description
}

resource "github_team_membership" "team_members" {
  for_each = { for m in var.team_members : m.username => m }

  team_id  = github_team.teams[each.value.team].id
  username = each.value.username
  role     = each.value.role

  depends_on = [github_team.teams]
}
