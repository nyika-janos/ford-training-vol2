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
