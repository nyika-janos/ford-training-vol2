# Step 03: Storage Bucket

## 🎯 Cél
Storage Bucket hozzáadása a Service Account mellé.

## 📦 Mit hozunk létre?
- ✅ 1x Service Account
- ✅ 1x Storage Bucket

**Összesen: 2 resource**

## 📝 Lépések

### 1. Navigálj a könyvtárba
```bash
cd step-03-storage/
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

Kimenet: `Plan: 2 to add, 0 to change, 0 to destroy.`

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
- `bucket_name` - A létrehozott Storage Bucket neve

## 🔍 Bucket ellenőrzése GCP Console-ban
1. GCP Console → Cloud Storage → Buckets
2. Keresd meg a bucket-et: `ford-training-430008-{your-name}-demo-bucket`

## 🗑️ Cleanup
```bash
terraform destroy
```

## 📚 Mit tanultunk?
- ✅ Több resource kezelése egyidejűleg
- ✅ Storage Bucket létrehozás
- ✅ Több output használata
- ✅ Resource naming conventions (project-name-bucket)

## ➡️ Következő lépés
👉 `step-04-bigquery/`