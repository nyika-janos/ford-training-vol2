# Step 01: Terraform Setup

## 🎯 Cél
Terraform telepítése és konfiguráció ellenőrzése. Ebben a lépésben még **nem hozunk létre** semmilyen GCP resource-t.

## ✅ Előfeltételek
- GCP CloudShell vagy lokális Terraform telepítés (>= 1.13.0)
- Service Account JSON kulcs

## 📝 Lépések

### 1. Navigálj a könyvtárba
```bash
cd step-01-setup/
```

### 2. Másold át a példafájlt
```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3. Terraform inicializálás
```bash
terraform init
```

Ez letölti a Google Provider-t.

### 4. Konfiguráció ellenőrzése
```bash
terraform validate
```

Kimenet: `Success! The configuration is valid.`

### 5. Plan futtatás (nincs resource létrehozás)
```bash
terraform plan
```

Kimenet: `No changes. Your infrastructure matches the configuration.`

## 📚 Mit tanultunk?
- ✅ Terraform telepítés ellenőrzése (`terraform -version`)
- ✅ Provider konfiguráció (`providers.tf`)
- ✅ Variable-ök definiálása (`variables.tf`)
- ✅ Variable-ök értékének megadása (`terraform.tfvars`)
- ✅ `terraform init` - provider letöltés
- ✅ `terraform validate` - szintaxis ellenőrzés
- ✅ `terraform plan` - változások előnézete

## ➡️ Következő lépés
👉 `step-02-service-account/`
```

---

### 2️⃣ `step-01-setup/providers.tf`

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

---

### 3️⃣ `step-01-setup/variables.tf`

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

---

### 4️⃣ `step-01-setup/terraform.tfvars.example`

```tfvars
# Másold át terraform.tfvars néven és töltsd ki!

environment = "demo"
```

---

## 🎯 **Összefoglalva - Step 01 fájlok:**

```
step-01-setup/
├── README.md
├── providers.tf
├── variables.tf
└── terraform.tfvars.example