variable "project_id" {
  description = "The GCP project ID"
  default     = "ford-training-430008"
}

variable "user_name" {
  description = "My name"
  default     = "Henry Ford"
}

variable "environment" {
  description = "The environment name - must be 'demo'"
  type        = string

  validation {
    condition     = var.environment == "demo"
    error_message = "The environment must be 'demo' for this training exercise."
  }
}

variable "region" {
  description = "The default region for resources"
  default     = "europe-west1"
}

variable "credentials_file" {
  description = "Path to the Service Account JSON key"
  default     = "../../../sa-key.json"
}

variable "dataform_repository" {
  description = "Dataform repository name (created in step-08)"
  type        = string
}

variable "dataform_workspace" {
  description = "Dataform workspace name (created in step-08)"
  type        = string
}
