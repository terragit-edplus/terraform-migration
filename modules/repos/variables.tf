variable "repos" {
  type = list(object({
    name        = string
    description = string
    private     = string
  }))
}
