# Step 01: Terraform Setup

## Cél
Terraform telepítése és konfiguráció ellenőrzése. Ebben a lépésben még **nem hozunk létre** semmilyen GCP resource-t.

## Előfeltételek
- GCP CloudShell vagy lokális Terraform telepítés
- Service Account JSON kulcs

## Lépések

1. **Navigálj a könyvtárba:**
```bash
cd step-01-setup/
```

2. **Terraform inicializálás:**
```bash
terraform init
```

3. **Konfiguráció ellenőrzése:**
```bash
terraform validate
```

4. **Plan futtatás (nincs resource létrehozás):**
```bash
terraform plan
```

Kimenet: `No changes. Your infrastructure matches the configuration.`

## Mit tanultunk?
- ✅ Terraform telepítés ellenőrzése
- ✅ Provider konfiguráció
- ✅ Variable-ök használata
- ✅ `terraform init`, `validate`, `plan` parancsok

## Következő lépés
👉 `step-02-service-account/`
```

### `step-01-setup/providers.tf`

```tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.7.0"
    }
  }
  required_version = ">= 1.13.0"
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.credentials_file)
}
```

### `step-01-setup/variables.tf`

```tf
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
```

### `step-01-setup/terraform.tfvars.example`

```tfvars
# Másold át terraform.tfvars néven és töltsd ki!

environment = "demo"
```

---

## 📝 **STEP 02: Service Account**

### `step-02-service-account/README.md`

```md
# Step 02: Service Account Creation

## Cél
Az első GCP resource létrehozása: **Service Account**.

## Mit hozunk létre?
- ✅ 1x Service Account

## Lépések

1. **Navigálj a könyvtárba:**
```bash
cd step-02-service-account/
```

2. **Másold át a tfvars példafájlt:**
```bash
cp terraform.tfvars.example terraform.tfvars
```

3. **Szerkeszd a terraform.tfvars-t:**
- Állítsd be a `user_name` változót a saját nevedre

4. **Terraform inicializálás:**
```bash
terraform init
```

5. **Plan:**
```bash
terraform plan
```

Kimenet: `Plan: 1 to add, 0 to change, 0 to destroy.`

6. **Apply:**
```bash
terraform apply
```

7. **Ellenőrzés:**
```bash
terraform show
```

## Outputs
- `service_account_email` - A létrehozott SA email címe

## Cleanup (ha szeretnéd törölni)
```bash
terraform destroy
```

## Mit tanultunk?
- ✅ `resource` blokk használata
- ✅ `local` variables használata
- ✅ `outputs` használata
- ✅ `terraform apply` és `destroy`

## Következő lépés
👉 `step-03-storage/`
```

### `step-02-service-account/providers.tf`

```tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.7.0"
    }
  }
  required_version = ">= 1.13.0"
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.credentials_file)
}
```

### `step-02-service-account/variables.tf`

```tf
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
```

### `step-02-service-account/locals.tf`

```tf
locals {
  # create dataset compatible name in two step
  name_lower           = lower(var.user_name)
  name_with_underscore = replace(local.name_lower, " ", "_")

  # create bucket and account name compatible name in one step
  name_with_hyphen = replace(lower(var.user_name), " ", "-")
}
```

### `step-02-service-account/main.tf`

```tf
# ============================================================================
# STEP 2: Service Account létrehozása
# ============================================================================

resource "google_service_account" "demo_sa" {
  account_id   = "terraform-demo-sa-${local.name_with_hyphen}"
  display_name = "Terraform Demo Service Account for ${var.user_name}"
}
```

### `step-02-service-account/outputs.tf`

```tf
output "service_account_email" {
  value       = google_service_account.demo_sa.email
  description = "The email address of the created Service Account"
}
```

### `step-02-service-account/terraform.tfvars.example`

```tfvars
# Másold át terraform.tfvars néven és töltsd ki!

user_name   = "Your Name"
environment = "demo"
```

---

## 📝 **STEP 03: Storage**

### `step-03-storage/README.md`

```md
# Step 03: Storage Bucket

## Cél
Storage Bucket hozzáadása a Service Account mellé.

## Mit hozunk létre?
- ✅ 1x Service Account
- ✅ 1x Storage Bucket

## Lépések

1. **Navigálj a könyvtárba:**
```bash
cd step-03-storage/
```

2. **Másold át a tfvars példafájlt:**
```bash
cp terraform.tfvars.example terraform.tfvars
```

3. **Terraform inicializálás:**
```bash
terraform init
```

4. **Plan:**
```bash
terraform plan
```

Kimenet: `Plan: 2 to add, 0 to change, 0 to destroy.`

5. **Apply:**
```bash
terraform apply
```

## Outputs
- `service_account_email`
- `bucket_name` - A létrehozott bucket neve

## Mit tanultunk?
- ✅ Több resource kezelése
- ✅ Storage Bucket létrehozás
- ✅ Több output használata

## Következő lépés
👉 `step-04-bigquery/`
```

### `step-03-storage/providers.tf`, `variables.tf`, `locals.tf`
*(Ugyanazok mint step-02-ben)*

### `step-03-storage/main.tf`

```tf
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
```

### `step-03-storage/outputs.tf`

```tf
output "service_account_email" {
  value       = google_service_account.demo_sa.email
  description = "The email address of the created Service Account"
}

output "bucket_name" {
  value       = google_storage_bucket.demo_bucket.name
  description = "The name of the created Storage Bucket"
}
```

### `step-03-storage/terraform.tfvars.example`
*(Ugyanaz mint step-02-ben)*

---

## 📝 **STEP 04: BigQuery**

### `step-04-bigquery/README.md`

```md
# Step 04: BigQuery Dataset & Table

## Cél
BigQuery Dataset és Table hozzáadása.

## Mit hozunk létre?
- ✅ 1x Service Account
- ✅ 1x Storage Bucket
- ✅ 1x BigQuery Dataset
- ✅ 1x BigQuery Table (2 oszloppal: id, timestamp)

## Lépések

1. **Navigálj a könyvtárba:**
```bash
cd step-04-bigquery/
```

2. **Másold át a tfvars példafájlt:**
```bash
cp terraform.tfvars.example terraform.tfvars
```

3. **Terraform inicializálás:**
```bash
terraform init
```

4. **Plan:**
```bash
terraform plan
```

Kimenet: `Plan: 4 to add, 0 to change, 0 to destroy.`

5. **Apply:**
```bash
terraform apply
```

## Outputs
- `service_account_email`
- `bucket_name`
- `dataset_id` - A BigQuery dataset azonosítója

## Mit tanultunk?
- ✅ BigQuery resource-ok kezelése
- ✅ Nested resource (table a dataset-ben)
- ✅ JSON schema definíció

## Következő lépés
👉 `step-05-iam/`
```

### `step-04-bigquery/providers.tf`, `variables.tf`, `locals.tf`
*(Ugyanazok)*

### `step-04-bigquery/main.tf`

```tf
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

# ============================================================================
# STEP 4: BigQuery dataset és table
# ============================================================================

resource "google_bigquery_dataset" "demo_dataset" {
  dataset_id = "${local.name_with_underscore}_demo_dataset"
  location   = var.region
}

resource "google_bigquery_table" "demo_table" {
  dataset_id = google_bigquery_dataset.demo_dataset.dataset_id
  table_id   = "${local.name_with_hyphen}-demo_table"

  schema = jsonencode([
    {
      name = "id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "timestamp"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    }
  ])
}
```

### `step-04-bigquery/outputs.tf`

```tf
output "service_account_email" {
  value       = google_service_account.demo_sa.email
  description = "The email address of the created Service Account"
}

output "bucket_name" {
  value       = google_storage_bucket.demo_bucket.name
  description = "The name of the created Storage Bucket"
}

output "dataset_id" {
  value       = google_bigquery_dataset.demo_dataset.dataset_id
  description = "The BigQuery dataset ID"
}
```

---

## 📝 **STEP 05: IAM**

### `step-05-iam/README.md`

```md
# Step 05: IAM Bindings

## Cél
IAM jogosultságok hozzáadása a Service Account-nak a Bucket-re és Dataset-re.

## Mit hozunk létre?
- ✅ 1x Service Account
- ✅ 1x Storage Bucket
- ✅ 1x BigQuery Dataset
- ✅ 1x BigQuery Table
- ✅ 1x Storage IAM Binding (Object Admin)
- ✅ 1x BigQuery IAM Binding (Data Editor)

**Összesen: 6 resource**

## Lépések

1. **Navigálj a könyvtárba:**
```bash
cd step-05-iam/
```

2. **Másold át a tfvars példafájlt:**
```bash
cp terraform.tfvars.example terraform.tfvars
```

3. **Terraform inicializálás:**
```bash
terraform init
```

4. **Plan:**
```bash
terraform plan
```

Kimenet: `Plan: 6 to add, 0 to change, 0 to destroy.`

5. **Apply:**
```bash
terraform apply
```

## IAM Roles
- **Storage Bucket:** `roles/storage.objectAdmin` (teljes RW jogosultság)
- **BigQuery Dataset:** `roles/bigquery.dataEditor` (RW jogosultság)

## Cleanup
```bash
terraform destroy
```

## Mit tanultunk?
- ✅ IAM binding-ok kezelése
- ✅ Service Account jogosultságok
- ✅ Resource dependencies

## Gratulálunk! 🎉
Befejezted a Terraform GCP training-et!
```

### `step-05-iam/providers.tf`, `variables.tf`, `locals.tf`
*(Ugyanazok)*

### `step-05-iam/main.tf`

```tf
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

# ============================================================================
# STEP 4: BigQuery dataset és table
# ============================================================================

resource "google_bigquery_dataset" "demo_dataset" {
  dataset_id = "${local.name_with_underscore}_demo_dataset"
  location   = var.region
}

resource "google_bigquery_table" "demo_table" {
  dataset_id = google_bigquery_dataset.demo_dataset.dataset_id
  table_id   = "${local.name_with_hyphen}-demo_table"

  schema = jsonencode([
    {
      name = "id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "timestamp"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    }
  ])
}

# ============================================================================
# STEP 5: IAM ROLE BINDINGS
# ============================================================================

# Storage Bucket - Object Admin (teljes RW jogosultság az objektumokra)
resource "google_storage_bucket_iam_member" "bucket_admin" {
  bucket = google_storage_bucket.demo_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.demo_sa.email}"
}

# BigQuery Dataset - Data Editor (RW jogosultság az adatokra)
resource "google_bigquery_dataset_iam_member" "dataset_editor" {
  dataset_id = google_bigquery_dataset.demo_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.demo_sa.email}"
}
```

### `step-05-iam/outputs.tf`

```tf
output "service_account_email" {
  value       = google_service_account.demo_sa.email
  description = "The email address of the created Service Account"
}

output "bucket_name" {
  value       = google_storage_bucket.demo_bucket.name
  description = "The name of the created Storage Bucket"
}

output "dataset_id" {
  value       = google_bigquery_dataset.demo_dataset.dataset_id
  description = "The BigQuery dataset ID"
}
```

---

## 📚 **Fő README.md** (terraform_demo_1/ gyökérben)

```md
# Terraform GCP Training - Step-by-Step Guide

## 📚 Áttekintés

Ez a training 5 lépésben vezet végig a Terraform alapjain GCP-n.

Minden lépés egy külön könyvtárban van, és **önállóan futtatható**.

## 🚀 Lépések

| Step | Könyvtár | Mit hoz létre? | Resources |
|------|----------|----------------|-----------|
| 01 | `step-01-setup/` | Nincs (csak setup) | 0 |
| 02 | `step-02-service-account/` | Service Account | 1 |
| 03 | `step-03-storage/` | SA + Bucket | 2 |
| 04 | `step-04-bigquery/` | SA + Bucket + BQ | 4 |
| 05 | `step-05-iam/` | Minden + IAM | 6 |

## 📖 Használat

### Általános lépések minden step-nél:

```bash
# 1. Navigálj a step könyvtárába
cd step-XX-name/

# 2. Másold át a példafájlt
cp terraform.tfvars.example terraform.tfvars

# 3. Szerkeszd a terraform.tfvars-t (állítsd be user_name-t)

# 4. Init
terraform init

# 5. Plan
terraform plan

# 6. Apply
terraform apply

# 7. (Opcionális) Cleanup
terraform destroy
```

### Gyors start:

```bash
# Step 1
cd step-01-setup/
terraform init
terraform validate

# Step 2
cd ../step-02-service-account/
cp terraform.tfvars.example terraform.tfvars
# Szerkeszd a tfvars-t!
terraform init
terraform apply

# Step 3
cd ../step-03-storage/
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply

# Step 4
cd ../step-04-bigquery/
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply

# Step 5 (Teljes)
cd ../step-05-iam/
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

## 🗑️ Cleanup

```bash
cd step-05-iam/
terraform destroy
```

## 📊 Végeredmény (Step 5)

- ✅ 1x Service Account
- ✅ 1x Storage Bucket (+ IAM)
- ✅ 1x BigQuery Dataset (+ IAM)
- ✅ 1x BigQuery Table
- ✅ 2x IAM Bindings

**Összesen: 6 GCP resource**

## 💡 Tippek

- Minden step önálló, saját `terraform.tfstate` fájllal
- A provider konfiguráció minden könyvtárban ugyanaz
- A variables ugyanazok, csak a main.tf bővül
- Mindig olvasd el a step README.md-t!

## 🎓 Mit tanulsz?

1. **Step 01:** Terraform setup és validáció
2. **Step 02:** Resource létrehozás, outputs
3. **Step 03:** Több resource kezelése
4. **Step 04:** Nested resources (table in dataset)
5. **Step 05:** IAM bindings és dependencies

Jó tanulást! 🚀