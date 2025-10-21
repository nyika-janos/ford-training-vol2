variable "project_id" {
  description = "The GCP project ID"
  default     = "ford-training-430008"
}

variable "user_name" {
  description = "My name"
  default     = "Henry Ford"
}

variable "region" {
  description = "The default region for resources"
  default     = "europe-west1"
}

variable "credentials_file" {
  description = "Path to the Service Account JSON key"
  default     = "../../sa-key.json"
}
