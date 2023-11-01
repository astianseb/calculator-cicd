variable "parent" {
  type = object({
    parent_type = string
    parent_id   = string
  })
  default = {
    parent_id   = null
    parent_type = null
  }
}

variable "billing_account" {
  type = string
}

variable "region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "github_repo_url" {
  type = string
  description = "Github repo in a format: https://github.com/<user>/<repo>.git "
}

variable "app_installation_id" {
  type = number
  description = "Github App ID from url: https://github.com/settings/installations/<ID>"
}

variable "github_secret" {
  type = string
  description = "PAT needs to have repo & read:user scopes turned on"
}