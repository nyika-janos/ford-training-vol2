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

variable "debug" {
  description = "Set debug flag"
  type        = bool

  validation {
    condition     = can(var.debug == true || var.debug == false)
    error_message = "Debug must be a boolean value (true or false)."
  }
}

variable "region" {
  description = "The default region for resources"
  default     = "europe-west1"
}

variable "credentials_file" {
  description = "Path to the Service Account JSON key"
  default     = "../../sa-key.json"
}
