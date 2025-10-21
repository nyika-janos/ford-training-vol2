# Step 04: BigQuery Dataset & Table

## 🎯 Cél
BigQuery Dataset és Table hozzáadása.

## 📦 Mit hozunk létre?
- ✅ 1x Service Account
- ✅ 1x Storage Bucket
- ✅ 1x BigQuery Dataset
- ✅ 1x BigQuery Table (2 oszloppal: id, timestamp)

**Összesen: 4 resource**

## 📝 Lépések

### 1. Navigálj a könyvtárba
```bash
cd step-04-bigquery/
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

Kimenet: `Plan: 4 to add, 0 to change, 0 to destroy.`

### 6. Apply (létrehozás)
```bash
terraform apply
```

### 7. Ellenőrzés
```bash
terraform output
```

## 📤 Outputs
- `service_account_email` - A Service Account email címe
- `bucket_name` - A Storage Bucket neve
- `dataset_id` - A BigQuery dataset azonosítója

## 🔍 BigQuery ellenőrzése GCP Console-ban
1. GCP Console → BigQuery
2. Keresd meg a dataset-et: `{your_name}_demo_dataset`
3. Nézd meg a table-t: `{your-name}-demo-table`
4. Nézd meg a schema-t (2 oszlop: id, timestamp)

## 🗑️ Cleanup
```bash
terraform destroy
```

## 📚 Mit tanultunk?
- ✅ BigQuery resource-ok kezelése
- ✅ Nested resource (table a dataset-ben)
- ✅ JSON schema definíció
- ✅ Resource dependencies (table függ dataset-től)
- ✅ Különböző naming conventions (underscore vs hyphen)

## ➡️ Következő lépés
👉 `step-05-iam/`

---

## 🎯 **Összefoglalva - Step 04 fájlok:**

```
step-04-bigquery/
├── README.md
├── providers.tf
├── variables.tf
├── locals.tf
├── main.tf            ← BŐVÜLT (SA + Bucket + BQ Dataset + Table)
├── outputs.tf         ← BŐVÜLT (3 output)
└── terraform.tfvars.example