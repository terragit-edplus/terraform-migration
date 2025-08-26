variable "teams" {
  type = list(object({
    name        = string
    description        = string
  }))
}

variable "team_members" {
  type = list(object({
    team = string
    username = string
    role     = string
  }))
}
