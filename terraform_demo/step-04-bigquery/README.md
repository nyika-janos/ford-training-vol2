# Step 04: BigQuery Dataset & Tables

## 🎯 Cél
BigQuery Dataset és két Table hozzáadása (log és raw_data táblák).

## ⚠️ **FONTOS: Előfeltételek**

**Step-02 ÉS Step-03 resource-ainak létezniük KELL!**

Ha még nem futtattad le őket:
```bash
# Step-02
cd ../step-02-service-account/
terraform apply

# Step-03
cd ../step-03-storage/
terraform apply
```

**NE futtass `terraform destroy`-t a step-02 vagy step-03-ban!**

---

## 📦 Mit hoz létre ez a step?

### ÚJ resource-ok (step-04 specifikusak):
- ✅ 1x BigQuery Dataset
- ✅ 1x BigQuery Log Table (6 oszlop)
- ✅ 1x BigQuery Raw Data Table (18 oszlop)

**Összesen: 3 ÚJ resource**

### Már létező resource-ok (data sources):
- 📌 Service Account (step-02-ből)
- 📌 Storage Bucket (step-03-ból)

---

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

⚠️ **FONTOS:** Ugyanazt a `user_name`-t használd, mint a step-02 és step-03-ban!

### 4. Terraform inicializálás
```bash
terraform init
```

### 5. Plan (előnézet)
```bash
terraform plan
```

Kimenet: `Plan: 3 to add, 0 to change, 0 to destroy.`

✅ **Ellenőrizd:** Csak **3 ÚJ** resource-ot hoz létre (nem 5-öt)!

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
- `bucket_name` - A Storage Bucket neve (data source, step-03-ból)
- `dataset_id` - A BigQuery dataset azonosítója (**ÚJ**)
- `log_table_id` - A log tábla azonosítója (**ÚJ**)
- `raw_data_table_id` - A raw data tábla azonosítója (**ÚJ**)

---

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

---

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

---

## 🗑️ Cleanup

**Csak a step-04 resource-ok törlése:**
```bash
terraform destroy
```

Ez NEM törli:
- Service Account (step-02)
- Storage Bucket (step-03)

---

## 📚 Mit tanultunk?
- ✅ **Data source** használata (már létező resource-okra hivatkozás)
- ✅ BigQuery Dataset létrehozás
- ✅ Több tábla létrehozása egy dataset-ben
- ✅ Részletes JSON schema definíció
- ✅ DATE és TIMESTAMP típusok használata
- ✅ Multi-step Terraform projektek

---

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