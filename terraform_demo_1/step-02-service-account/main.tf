# ============================================================================
# STEP 2: Service Account létrehozása
# ============================================================================

resource "google_service_account" "demo_sa" {
  account_id   = "terraform-demo-sa-${local.name_with_hyphen}"
  display_name = "Terraform Demo Service Account for ${var.user_name}"
}
