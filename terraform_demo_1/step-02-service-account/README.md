# Step 02: Service Account Creation

## 🎯 Cél
Az első GCP resource létrehozása: **Service Account**.

## 📦 Mit hozunk létre?
- ✅ 1x Service Account

## 📝 Lépések

### 1. Navigálj a könyvtárba
```bash
cd step-02-service-account/
```

### 2. Másold át a példafájlt
```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3. Szerkeszd a terraform.tfvars-t
Állítsd be a `user_name` változót a saját nevedre!

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

Kimenet: `Plan: 1 to add, 0 to change, 0 to destroy.`

### 6. Apply (létrehozás)
```bash
terraform apply
```

Írj `yes`-t a megerősítéshez.

### 7. Ellenőrzés
```bash
terraform show
```

vagy

```bash
terraform output
```

## 📤 Outputs
- `service_account_email` - A létrehozott Service Account email címe

## 🗑️ Cleanup (ha szeretnéd törölni)
```bash
terraform destroy
```

## 📚 Mit tanultunk?
- ✅ `resource` blokk használata
- ✅ `local` variables használata (locals.tf)
- ✅ String interpolation (`${...}`)
- ✅ `outputs` használata
- ✅ `terraform apply` - resource létrehozás
- ✅ `terraform destroy` - resource törlés
- ✅ `terraform output` - kimeneti értékek lekérdezése

## ➡️ Következő lépés
👉 `step-03-storage/`
```
