# ============================================================================
# STEP 2: Service Account létrehozása
# ============================================================================

resource "google_service_account" "demo_sa" {
  account_id   = "terraform-demo-sa-${local.name_with_hyphen}"
  display_name = "Terraform Demo Service Account for ${var.user_name}"
}

# ============================================================================
# STEP 3: Storage bucket létrehozása
# ============================================================================

resource "google_storage_bucket" "demo_bucket" {
  name     = "${var.project_id}-${local.name_with_hyphen}-demo-bucket"
  location = var.region
}
