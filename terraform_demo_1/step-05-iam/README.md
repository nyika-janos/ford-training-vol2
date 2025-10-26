# Step 05: IAM Bindings

## 🎯 Cél
IAM jogosultságok hozzáadása a Service Account-nak a Bucket-re és Dataset-re.

## ⚠️ **FONTOS: Előfeltételek**

**Step-02, Step-03 ÉS Step-04 resource-ainak létezniük KELL!**

Ha még nem futtattad le őket:
```bash
# Step-02
cd ../step-02-service-account/
terraform apply

# Step-03
cd ../step-03-storage/
terraform apply

# Step-04
cd ../step-04-bigquery/
terraform apply
```

**NE futtass `terraform destroy`-t az előző step-ekben!**

---

## 📦 Mit hoz létre ez a step?

### ÚJ resource-ok (step-05 specifikusak):
- ✅ 1x Storage IAM Binding (Object Admin)
- ✅ 1x BigQuery IAM Binding (Data Editor)

**Összesen: 2 ÚJ resource**

### Már létező resource-ok (data sources):
- 📌 Service Account (step-02-ből)
- 📌 Storage Bucket (step-03-ból)
- 📌 BigQuery Dataset (step-04-ből)
- 📌 BigQuery Log Table (step-04-ből)
- 📌 BigQuery Raw Data Table (step-04-ből)

---

## 🔐 IAM Roles
- **Storage Bucket:** `roles/storage.objectAdmin` (teljes RW jogosultság az objektumokra)
- **BigQuery Dataset:** `roles/bigquery.dataEditor` (RW jogosultság az adatokra)

---

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

⚠️ **FONTOS:** Ugyanazt a `user_name`-t használd, mint az előző step-ekben!

### 4. Terraform inicializálás
```bash
terraform init
```

### 5. Plan (előnézet)
```bash
terraform plan
```

Kimenet: `Plan: 2 to add, 0 to change, 0 to destroy.`

✅ **Ellenőrizd:** Csak **2 ÚJ** resource-ot hoz létre (nem 6-ot)!

### 6. Apply (létrehozás)
```bash
terraform apply
```

### 7. Ellenőrzés
```bash
terraform output
```

---

## 📤 Outputs
- `service_account_email` - Service Account email (data source, step-02-ből)
- `bucket_name` - Storage Bucket neve (data source, step-03-ból)
- `dataset_id` - BigQuery dataset ID (data source, step-04-ből)
- `log_table_id` - Log tábla ID (data source, step-04-ből)
- `raw_data_table_id` - Raw data tábla ID (data source, step-04-ből)

---

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

---

## 🗑️ Cleanup

**Csak a step-05 resource-ok törlése:**
```bash
terraform destroy
```

Ez NEM törli:
- Service Account (step-02)
- Storage Bucket (step-03)
- BigQuery Dataset és Tables (step-04)

**Teljes cleanup (fordított sorrendben):**
```bash
# 1. Step-05 IAM bindings
cd step-05-iam/
terraform destroy

# 2. Step-04 BigQuery
cd ../step-04-bigquery/
terraform destroy

# 3. Step-03 Storage
cd ../step-03-storage/
terraform destroy

# 4. Step-02 Service Account
cd ../step-02-service-account/
terraform destroy
```

---

## 📚 Mit tanultunk?
- ✅ **Data source** használata (már létező resource-okra hivatkozás)
- ✅ IAM binding-ok kezelése
- ✅ Service Account jogosultságok
- ✅ Resource dependencies
- ✅ Role-ok típusai (storage.objectAdmin, bigquery.dataEditor)
- ✅ Member formátum: `serviceAccount:${email}`
- ✅ Multi-step Terraform projektek

---

## 🎓 Gratulálunk! 🎉

Befejezted az első 5 lépését a Terraform GCP training-nek!

### Mit tanultál?
1. ✅ Terraform alapok (init, plan, apply, destroy)
2. ✅ Provider konfiguráció
3. ✅ Variables és locals használata
4. ✅ Resource létrehozás és data sources
5. ✅ Outputs kezelése
6. ✅ IAM jogosultságok

---

## ➡️ Következő lépés
👉 `step-06-cloud-function-processor/` - Cloud Function és Pub/Sub

---

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