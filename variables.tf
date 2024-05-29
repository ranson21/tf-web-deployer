variable "bucket_name" {
  description = "Storage bucket where the assets will be deployed"
  type        = string
}

variable "release_version" {
  description = "Version of the assets to deploy"
  type        = string
}

variable "owner" {
  description = "Repository owner"
  type        = string
}

variable "repo" {
  description = "Repository name"
  type        = string
}

variable "asset_name" {
  description = "Name of the release version asset"
  type        = string
  default     = "release.zip"
}

variable "asset_dir" {
  description = "Directory where the assets are located"
  type        = string
  default     = "build"
}
