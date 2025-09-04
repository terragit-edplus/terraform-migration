variable "repos" {
  type = list(object({
    name        = string
    description = string
    visibility     = string
  }))
}

variable "branches" {
  type = list(object({
    repo   = string
    branch = string
    minPRCount       = optional(number, 0)
    users  = string
    teams  = string
    codeOwnerReviewRequired = optional(bool, false)
  }))
}

variable "team_permissions"{
  type = list(object({
    repo = string
    team = string
    permission = string
  }))
}

variable "user_permissions"{
  type = list(object({
    repo = string
    user = string
    permission = string
  }))
}
