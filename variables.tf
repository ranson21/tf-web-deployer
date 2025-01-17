# variables.tf
variable "owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "repo" {
  description = "GitHub repository name"
  type        = string
}

variable "release_version" {
  description = "Release version/tag to deploy"
  type        = string
}

variable "asset_name" {
  description = "Name of the asset to download from the release"
  type        = string
}

variable "bucket_name" {
  description = "Name of the GCS bucket to deploy to"
  type        = string
}

variable "triggers" {
  description = "Map of triggers to force deployment updates"
  type        = map(string)
  default     = {}
}

variable "github_token" {
  description = "GitHub token for repository access"
  type        = string
  sensitive   = true

  validation {
    condition     = var.github_token != ""
    error_message = "GitHub token cannot be empty."
  }
}

variable "host" {
  description = "Deployment host type (gcs or firebase)"
  type        = string
  validation {
    condition     = contains(["gcs", "firebase"], var.host)
    error_message = "Host must be either 'gcs' or 'firebase'."
  }
}
