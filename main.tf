provider "github" {
    owner = var.github_organization
    app_auth {
        id              = var.app_id
        installation_id = var.app_installation_id
        pem_file        = var.app_pem_file
    }
}

resource "github_repository" "test" {
  name        = "test-repo"
  description = "A test repository"
  visibility  = "private"
}
