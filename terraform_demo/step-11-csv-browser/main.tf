# ============================================================================
# DATA SOURCES - Már létező resource-ok
# ============================================================================

data "google_service_account" "demo_sa" {
  account_id = "terraform-demo-sa-${local.name_with_hyphen}"
}

data "google_storage_bucket" "csv_export_bucket" {
  name = "${var.project_id}-${local.name_with_hyphen}-csv-exports"
}

# ============================================================================
# STEP 11: CSV Browser Website (Cloud Run)
# ============================================================================

# Cloud Run service
resource "google_cloud_run_service" "csv_browser" {
  name     = "${local.name_with_hyphen}-csv-browser"
  location = var.region

  template {
    spec {
      service_account_name = data.google_service_account.demo_sa.email

      containers {
        image = local.docker_image

        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }

        env {
          name  = "BUCKET_NAME"
          value = data.google_storage_bucket.csv_export_bucket.name
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "10"
        "autoscaling.knative.dev/minScale" = "0"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  lifecycle {
    ignore_changes = [
      template[0].metadata[0].annotations["run.googleapis.com/client-name"],
      template[0].metadata[0].annotations["run.googleapis.com/client-version"],
    ]
  }
}

# IAM - Public access (allUsers)
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.csv_browser.name
  location = google_cloud_run_service.csv_browser.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# IAM - Storage Object Viewer (ha még nincs meg a demo SA-nak)
resource "google_storage_bucket_iam_member" "csv_bucket_viewer" {
  bucket = data.google_storage_bucket.csv_export_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_service_account.demo_sa.email}"
}
