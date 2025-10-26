# Step 03: Storage Bucket

## 🎯 Cél
Storage Bucket hozzáadása a meglévő Service Account mellé.

## ⚠️ **FONTOS: Előfeltételek**

**Step-02 resource-ainak létezniük KELL!**

Ha még nem futtattad le a step-02-t:
```bash
cd ../step-02-service-account/
terraform apply
```

**NE futtass `terraform destroy`-t a step-02-ben!**

---

## 📦 Mit hoz létre ez a step?

### ÚJ resource (step-03 specifikus):
- ✅ 1x Storage Bucket

**Összesen: 1 ÚJ resource**

### Már létező resource (data source):
- 📌 Service Account (step-02-ből)

---

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

⚠️ **FONTOS:** Ugyanazt a `user_name`-t használd, mint a step-02-ben!

### 4. Terraform inicializálás
```bash
terraform init
```

### 5. Plan (előnézet)
```bash
terraform plan
```

Kimenet: `Plan: 1 to add, 0 to change, 0 to destroy.`

✅ **Ellenőrizd:** Csak **1 ÚJ** resource-ot hoz létre (nem 2-t)!

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
- `service_account_email` - A Service Account email címe (data source, step-02-ből)
- `bucket_name` - A létrehozott Storage Bucket neve (**ÚJ**)

---

## 🔍 Bucket ellenőrzése GCP Console-ban
1. GCP Console → Cloud Storage → Buckets
2. Keresd meg a bucket-et: `ford-training-430008-{your-name}-demo-bucket`

---

## 🗑️ Cleanup

**Csak a step-03 resource törlése:**
```bash
terraform destroy
```

Ez NEM törli a Service Account-ot (az a step-02-ben van).

Ha törölni akarod a Service Account-ot is:
```bash
cd ../step-02-service-account/
terraform destroy
```

---

## 📚 Mit tanultunk?
- ✅ **Data source** használata (már létező resource-ra hivatkozás)
- ✅ Storage Bucket létrehozás
- ✅ Multi-step Terraform projektek
- ✅ Resource naming conventions

---

## ➡️ Következő lépés
👉 `step-04-bigquery/`

---

## 🎯 **Összefoglalva - Step 03 fájlok:**

```
step-03-storage/
├── README.md
├── providers.tf
├── variables.tf
├── locals.tf
├── main.tf            ← BŐVÜLT (SA + Bucket)
├── outputs.tf         ← BŐVÜLT (2 output)
└── terraform.tfvars.example