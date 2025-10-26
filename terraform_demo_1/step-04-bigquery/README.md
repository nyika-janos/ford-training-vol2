# Step 04: BigQuery Dataset & Tables

## 🎯 Cél
BigQuery Dataset és két Table hozzáadása (log és raw_data táblák).

## 📦 Mit hozunk létre?
- ✅ 1x Service Account
- ✅ 1x Storage Bucket
- ✅ 1x BigQuery Dataset
- ✅ 1x BigQuery Log Table (6 oszlop: timestamp, log_level, message, stb.)
- ✅ 1x BigQuery Raw Data Table (18 oszlop: superstore adatokhoz)

**Összesen: 5 resource**

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

Kimenet: `Plan: 5 to add, 0 to change, 0 to destroy.`

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
- `log_table_id` - A log tábla azonosítója
- `raw_data_table_id` - A raw data tábla azonosítója

## 🔍 BigQuery ellenőrzése GCP Console-ban

### Dataset:
1. GCP Console → BigQuery
2. Keresd meg a dataset-et: `{your_name}_demo_dataset`

### Log Table:
3. Nézd meg a `{your-name}-log-table` táblát
4. Schema:
   - `timestamp` (TIMESTAMP, REQUIRED) - Log időpontja
   - `log_level` (STRING, REQUIRED) - Log szint (INFO, WARNING, ERROR, DEBUG)
   - `message` (STRING, REQUIRED) - Log üzenet
   - `source` (STRING, NULLABLE) - Forrás (modul/komponens)
   - `user_id` (STRING, NULLABLE) - Felhasználó ID
   - `additional_info` (STRING, NULLABLE) - További info (JSON)

### Raw Data Table:
5. Nézd meg a `{your-name}-raw-data-table` táblát
6. Schema: 18 oszlop superstore adatokhoz
   - `row_id` (INTEGER) - Sor ID
   - `order_id` (STRING) - Rendelés ID
   - `order_date` (DATE) - Rendelés dátuma
   - `ship_date` (DATE) - Szállítás dátuma
   - `ship_mode` (STRING) - Szállítási mód
   - `customer_id` (STRING) - Ügyfél ID
   - `customer_name` (STRING) - Ügyfél neve
   - `segment` (STRING) - Szegmens
   - `country` (STRING) - Ország
   - `city` (STRING) - Város
   - `state` (STRING) - Állam
   - `postal_code` (FLOAT) - Irányítószám
   - `region` (STRING) - Régió
   - `product_id` (STRING) - Termék ID
   - `category` (STRING) - Kategória
   - `sub_category` (STRING) - Alkategória
   - `product_name` (STRING) - Termék neve
   - `sales` (FLOAT) - Eladási érték

## 💡 Adatok betöltése (példa)

### Log Table-be:
```sql
INSERT INTO `{project_id}.{your_name}_demo_dataset.{your-name}-log-table`
(timestamp, log_level, message, source, user_id, additional_info)
VALUES
(CURRENT_TIMESTAMP(), 'INFO', 'Application started', 'main.py', 'user123', '{"version": "1.0"}');
```

### Raw Data Table-be (CSV import):
1. BigQuery Console → Dataset → Table
2. **Create table from:** Upload
3. **Select file:** superstore_final_dataset_1.csv
4. **File format:** CSV
5. **Table:** `{your-name}-raw-data-table`
6. **Auto detect:** Schema and input parameters
7. **Create table**

## 🗑️ Cleanup
```bash
terraform destroy
```

## 📚 Mit tanultunk?
- ✅ BigQuery resource-ok kezelése
- ✅ Több tábla létrehozása egy dataset-ben
- ✅ Részletes JSON schema definíció
- ✅ DATE és TIMESTAMP típusok használata
- ✅ Resource dependencies (táblák függnek dataset-től)
- ✅ Különböző naming conventions (underscore vs hyphen)
- ✅ Schema description-ök használata

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
├── main.tf            ← BŐVÜLT (SA + Bucket + BQ Dataset + 2 BQ Table)
├── outputs.tf         ← BŐVÜLT (3 output)
└── terraform.tfvars.example