terraform {
  required_version = ">= 1.12.2"

  backend "remote" {
    organization = "terragit-edplus"

    workspaces {
      name = "github-workspace"
    }
  }
}
