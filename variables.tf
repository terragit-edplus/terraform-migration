variable "github_organization" {
  description = "GitHub Organization Name"
  type        = string
}

variable "app_id" {
  description = "GitHub App ID"
  type        = string
}

variable "app_installation_id" {
  description = "GitHub Installation ID"
  type        = string
}

variable "app_pem_file" {
  description = "GitHub App Private Key PEM file path"
  type        = string
  default     = "github_app.pem"
}

variable "config_path" {
  default     = "data/snapshot.json"
  description = "Path to Google Sheets snapshot"
}