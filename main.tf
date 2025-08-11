provider "github" {
    owner = var.github_organization
    app_auth {
        id              = var.github_app_id
        installation_id = var.github_installation_id
        pem_file        = var.github_app_private_key
    }
}