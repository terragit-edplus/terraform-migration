variable "members" {
  type = list(object({
    username = string
    role     = string
  }))
}
