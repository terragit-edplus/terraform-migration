terraform {
  required_version = ">= 1.4"

  backend "remote" {
    organization = "terragit-edplus"

    workspaces {
      name = "github-workspace"
    }
  }
}