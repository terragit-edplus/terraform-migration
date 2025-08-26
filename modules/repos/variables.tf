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
  }))
}