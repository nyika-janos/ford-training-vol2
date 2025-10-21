# Step 05: IAM Bindings

## 🎯 Cél
IAM jogosultságok hozzáadása a Service Account-nak a Bucket-re és Dataset-re.

## 📦 Mit hozunk létre?
- ✅ 1x Service Account
- ✅ 1x Storage Bucket
- ✅ 1x BigQuery Dataset
- ✅ 1x BigQuery Table
- ✅ 1x Storage IAM Binding (Object Admin)
- ✅ 1x BigQuery IAM Binding (Data Editor)

**Összesen: 6 resource**

## 🔐 IAM Roles
- **Storage Bucket:** `roles/storage.objectAdmin` (teljes RW jogosultság az objektumokra)
- **BigQuery Dataset:** `roles/bigquery.dataEditor` (RW jogosultság az adatokra)

## 📝 Lépések

### 1. Navigálj a könyvtárba
```bash
cd step-05-iam/
```

### 2. Másold át a példafájlt
```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3. Szerkeszd a terraform.tfvars-t
```tfvars
user_name   = "Gipsz Jakab"
environment = "demo"
```

### 4. Terraform inicializálás
```bash
terraform init
```

### 5. Plan (előnézet)
```bash
terraform plan
```

Kimenet: `Plan: 6 to add, 0 to change, 0 to destroy.`

### 6. Apply (létrehozás)
```bash
terraform apply
```

### 7. Ellenőrzés
```bash
terraform output
```

## 📤 Outputs
- `service_account_email`
- `bucket_name`
- `dataset_id`

## 🔍 IAM ellenőrzése GCP Console-ban

### Storage Bucket IAM:
1. GCP Console → Cloud Storage → Buckets
2. Kattints a bucket-re
3. **Permissions** fül
4. Keresd meg a Service Account-ot → Role: `Storage Object Admin`

### BigQuery Dataset IAM:
1. GCP Console → BigQuery
2. Kattints a dataset-re
3. **Sharing** → **Permissions**
4. Keresd meg a Service Account-ot → Role: `BigQuery Data Editor`

## 🗑️ Cleanup
```bash
terraform destroy
```

**FONTOS:** A destroy először az IAM binding-okat törli, majd a resource-okat, végül a Service Account-ot.

## 📚 Mit tanultunk?
- ✅ IAM binding-ok kezelése
- ✅ Service Account jogosultságok
- ✅ Resource dependencies (IAM függ SA-tól és resource-tól)
- ✅ Role-ok típusai (storage.objectAdmin, bigquery.dataEditor)
- ✅ Member formátum: `serviceAccount:${email}`

## 🎓 Gratulálunk! 🎉

Befejezted a Terraform GCP training-et!

### Mit tanultál?
1. ✅ Terraform alapok (init, plan, apply, destroy)
2. ✅ Provider konfiguráció
3. ✅ Variables és locals használata
4. ✅ Resource létrehozás és függőségek
5. ✅ Outputs kezelése
6. ✅ IAM jogosultságok

### Következő lépések:
- Próbálj ki más GCP resource-okat (Cloud Function, Pub/Sub, etc.)
- Tanulj módosításokról (resource frissítés)
- Nézz utána Terraform modules-nak
- Próbálj ki remote state-et (GCS backend)


## 🎯 **Összefoglalva - Step 05 fájlok:**

```
step-05-iam/
├── README.md
├── providers.tf
├── variables.tf
├── locals.tf
├── main.tf            ← BŐVÜLT (Minden + IAM bindings)
├── outputs.tf
└── terraform.tfvars.example
```

**7 fájl összesen** ✅

---

## 🎊 **KÉSZ! Minden Step elkészült!**

```
terraform_demo_1/
├── step-01-setup/           (4 fájl)
├── step-02-service-account/ (7 fájl)
├── step-03-storage/         (7 fájl)
├── step-04-bigquery/        (7 fájl)
└── step-05-iam/             (7 fájl)