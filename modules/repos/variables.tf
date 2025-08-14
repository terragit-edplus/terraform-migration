variable "repos" {
  type = list(object({
    name        = string
    description = string
    visibility     = string
  }))
}
