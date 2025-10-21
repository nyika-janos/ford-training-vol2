# Terraform GCP Training - Step-by-Step Guide 🚀

Terraform alapok gyakorlati példákkal Google Cloud Platform-on.

---

## 📚 Áttekintés

Ez a training **6 lépésben** vezet végig a Terraform alapjain GCP-n, fokozatosan bővülő példákkal.

Minden lépés egy külön könyvtárban van, és **önállóan futtatható**.

---

## 🎯 Lépések

| Step | Könyvtár | Leírás | Resources |
|------|----------|--------|-----------|
| **00** | `step-00/` | Előkészületek (Terraform telepítés, SA kulcs) | 0 |
| **01** | `step-01-setup/` | Terraform setup és konfiguráció ellenőrzés | 0 |
| **02** | `step-02-service-account/` | Service Account létrehozása | 1 |
| **03** | `step-03-storage/` | Storage Bucket hozzáadása | 2 |
| **04** | `step-04-bigquery/` | BigQuery Dataset és Table | 4 |
| **05** | `step-05-iam/` | IAM jogosultságok (teljes verzió) | 6 |

---

## 🚀 Gyors Start

### 1️⃣ Előkészületek (Step 00)

```bash
# Navigálj a step-00 könyvtárba és kövesd az útmutatót
cd step-00/
cat README.md
```

**Mit csinálsz:**
- Terraform telepítés/upgrade
- Service Account kulcs letöltése
- GitHub repo klónozása

### 2️⃣ Lépésről lépésre haladás

Minden step-nél ugyanaz a folyamat:

```bash
# 1. Navigálj a step könyvtárába
cd step-01-setup/

# 2. Másold át a példafájlt
cp terraform.tfvars.example terraform.tfvars

# 3. Szerkeszd a terraform.tfvars-t (állítsd be user_name-t)
nano terraform.tfvars

# 4. Init
terraform init

# 5. Plan
terraform plan

# 6. Apply
terraform apply

# 7. (Opcionális) Cleanup
terraform destroy
```

**Minden step-hez tartozik részletes README!**

---

## 📖 Részletes Lépések

### Step 00: Prerequisites & Setup
**Könyvtár:** `step-00/`

Terraform telepítés, Service Account kulcs beszerzése, repo klónozása.

**Mit tanulsz:**
- GCP CloudShell használat
- Terraform telepítés
- SA kulcs kezelés

---

### Step 01: Terraform Setup
**Könyvtár:** `step-01-setup/`

Terraform konfiguráció ellenőrzése. **Nincs resource létrehozás.**

**Mit tanulsz:**
- `terraform init` - provider letöltés
- `terraform validate` - konfiguráció ellenőrzés
- `terraform plan` - előnézet
- Provider és variable konfiguráció

---

### Step 02: Service Account
**Könyvtár:** `step-02-service-account/`

**Létrehoz:**
- ✅ 1x Service Account

**Mit tanulsz:**
- Resource létrehozás
- Local variables használata
- String interpolation
- Outputs

---

### Step 03: Storage Bucket
**Könyvtár:** `step-03-storage/`

**Létrehoz:**
- ✅ 1x Service Account
- ✅ 1x Storage Bucket

**Mit tanulsz:**
- Több resource kezelése
- Storage Bucket konfiguráció
- Naming conventions

---

### Step 04: BigQuery
**Könyvtár:** `step-04-bigquery/`

**Létrehoz:**
- ✅ 1x Service Account
- ✅ 1x Storage Bucket
- ✅ 1x BigQuery Dataset
- ✅ 1x BigQuery Table (2 oszlop)

**Mit tanulsz:**
- BigQuery resource-ok
- Nested resources (table a dataset-ben)
- JSON schema definíció
- Resource dependencies

---

### Step 05: IAM Bindings (Teljes verzió)
**Könyvtár:** `step-05-iam/`

**Létrehoz:**
- ✅ 1x Service Account
- ✅ 1x Storage Bucket (+ IAM)
- ✅ 1x BigQuery Dataset (+ IAM)
- ✅ 1x BigQuery Table
- ✅ 2x IAM Bindings

**Összesen: 6 GCP resource**

**Mit tanulsz:**
- IAM role bindings
- Service Account jogosultságok
- `roles/storage.objectAdmin`
- `roles/bigquery.dataEditor`

---

## 🗑️ Cleanup

```bash
# Navigálj az utolsó step-hez
cd step-05-iam/

# Töröld az összes létrehozott resource-t
terraform destroy
```

**FONTOS:** A destroy sorrendben törli a resource-okat (IAM → Resources → SA).

---

## 💡 Tippek

- ✅ Minden step önálló, saját `terraform.tfstate` fájllal
- ✅ A provider konfiguráció minden könyvtárban ugyanaz
- ✅ A variables ugyanazok, csak a `main.tf` bővül
- ✅ **Mindig olvasd el a step README.md-t!**
- ✅ Ha elakadsz, nézd meg a `terraform plan` kimenetét
- ✅ A `terraform output` mutatja a létrehozott resource-okat

---

## 🎓 Mit tanulsz összesen?

### Terraform alapok:
1. ✅ Terraform telepítés és setup
2. ✅ Provider konfiguráció (Google)
3. ✅ Variables és locals használata
4. ✅ Resource létrehozás és kezelés
5. ✅ Outputs
6. ✅ `init`, `plan`, `apply`, `destroy` parancsok

### GCP resource-ok:
1. ✅ Service Account
2. ✅ Storage Bucket
3. ✅ BigQuery Dataset & Table
4. ✅ IAM Bindings

### Best practices:
1. ✅ Naming conventions
2. ✅ Resource dependencies
3. ✅ IAM jogosultságok
4. ✅ Infrastructure as Code

---

## 📊 Végeredmény

A Step 05 végén a következő infrastruktúra jön létre:

```
GCP Project: ford-training-430008
├── Service Account: terraform-demo-sa-{your-name}
├── Storage Bucket: ford-training-430008-{your-name}-demo-bucket
│   └── IAM: Storage Object Admin → SA
├── BigQuery Dataset: {your_name}_demo_dataset
│   ├── IAM: BigQuery Data Editor → SA
│   └── Table: {your-name}-demo-table
│       ├── Column: id (STRING, REQUIRED)
│       └── Column: timestamp (TIMESTAMP, NULLABLE)
```

---

## 🔗 Hasznos linkek

- [Terraform Documentation](https://www.terraform.io/docs)
- [Google Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

## ❓ Gyakori problémák

### `terraform init` error
```bash
# Ellenőrizd a providers.tf-et
# Ellenőrizd az internet kapcsolatot
```

### `terraform apply` permission denied
```bash
# Ellenőrizd a Service Account kulcs elérési útját (credentials_file)
# Ellenőrizd a SA jogosultságokat a GCP Console-ban
```

### Resource already exists
```bash
# Valaki már létrehozta ugyanazzal a névvel
# Változtasd meg a user_name változót a terraform.tfvars-ban
```

---

## 🎉 Gratulálunk!

Ha végigcsináltad az összes lépést, készen állsz a Terraform használatára GCP-n!

### Következő lépések:
- 🔄 Próbálj ki resource módosításokat
- 📦 Nézz utána Terraform modules-nak
- 🌐 Próbálj ki remote state-et (GCS backend)
- 🚀 Próbálj ki más GCP resource-okat (Cloud Function, Pub/Sub, stb.)

---

**Készítette:** Training Team  
**Verzió:** 1.0  
**Utolsó frissítés:** 2025