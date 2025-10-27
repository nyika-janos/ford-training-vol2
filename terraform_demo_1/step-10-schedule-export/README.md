# Step 10: Scheduled CSV Export

## 🎯 Cél
Cloud Scheduler és Cloud Function Gen2 létrehozása, ami **óránként automatikusan** exportálja a Dataform aggregált táblákat CSV formátumba egy dedikált Storage Bucket-be.

## ⚠️ **FONTOS: Előfeltételek**

**Step-02, Step-03, Step-04, Step-05, Step-06 ÉS Step-08 resource-ainak létezniük KELL!**

**Step-08 Dataform workflow-nak FUTNIA KELLETT!** (Az aggregált táblák adatokkal fel vannak töltve)

Ha még nem futtattad le őket sorrendben:
```bash
cd ../step-02-service-account/ && terraform apply
cd ../step-03-storage/ && terraform apply
cd ../step-04-bigquery/ && terraform apply
cd ../step-05-iam/ && terraform apply
cd ../step-06-cloud-function-processor/ && terraform apply
cd ../step-08-dataform/ && terraform apply
```

**NE futtass `terraform destroy`-t az előző step-ekben!**

---

## 📦 Mit hoz létre ez a step?

### ÚJ resource-ok (step-10 specifikusak):
- ✅ 1x Storage Bucket (CSV export-ok tárolására, 30 napos lifecycle)
- ✅ 1x Storage Bucket (Cloud Function forráskódjához)
- ✅ 1x Storage Bucket Object (function ZIP fájl)
- ✅ 1x **Cloud Function Gen2** (HTTP trigger, Python 3.12)
- ✅ 1x **Cloud Scheduler Job** (óránkénti futás)
- ✅ 3x IAM Binding (Cloud Run Invoker, Storage Admin, BQ Viewer)

**Összesen: 9 ÚJ resource**

### Már létező resource-ok (data sources):
- 📌 Service Account (step-02-ből)
- 📌 BigQuery Dataset (step-04-ből)
- 📌 BigQuery Log Table (step-04-ből)
- 📌 5x BigQuery Aggregált Táblák (step-08-ból):
  - `monthly_orders_by_ship_mode`
  - `monthly_orders_us_state`
  - `monthly_favorite_product`
  - `monthly_customer_segment_analysis`
  - `monthly_category_revenue_trend`

---

## 🚀 Cloud Scheduler + Cloud Function Gen2

### Működés:
1. ⏰ **Cloud Scheduler** óránként HTTP POST request-et küld (minden óra 0. percében)
2. 📥 **Cloud Function** fogadja a request-et
3. 🔍 **BigQuery query** minden aggregált táblára (5 db)
4. 📊 **Pandas DataFrame** létrehozása
5. 💾 **CSV export** memóriában
6. ☁️ **Upload GCS**-be struktúrált mappákba:
   ```
   csv-export-bucket/
   ├── monthly_orders_by_ship_mode/
   │   ├── 2024-01-15_060000.csv
   │   ├── 2024-01-15_070000.csv
   │   └── 2024-01-15_080000.csv
   ├── monthly_orders_us_state/
   │   └── ...
   ```
7. 📝 **Logging** BigQuery log táblába

### Előnyök:
- ✅ **Automatikus ütemezés** - óránként fut, manual beavatkozás nélkül
- ✅ **Pandas export** - gyors és egyszerű kis adatmennyiségnél
- ✅ **Strukturált tárolás** - mappák táblánként
- ✅ **Időbélyegzett fájlok** - egyszerű verziókövetés
- ✅ **30 napos lifecycle** - automatikus cleanup régi fájlokból
- ✅ **Retry policy** - újrapróbálkozás hiba esetén
- ✅ **Teljes logging** - minden export naplózva

---

## ⏰ Cloud Scheduler konfiguráció

- **Schedule:** `0 * * * *` (óránként, a 0. percben)
- **Timezone:** `Europe/Budapest`
- **Timeout:** 320 másodperc
- **Retry:** 3 alkalommal
- **Trigger:** HTTP POST a Cloud Function URL-re
- **Auth:** OIDC token (Service Account)

**Példa futási időpontok:**
- 06:00, 07:00, 08:00, 09:00... (minden egész óra)

---

## 📝 Lépések

### 1. Navigálj a könyvtárba
```bash
cd step-10-scheduled-export/
```

### 2. Cloud Function kód ellenőrzése

A `function_source/` könyvtárban találod:
- `main.py` - CSV export Python 3.12 kód
- `requirements.txt` - Python függőségek (pandas, BigQuery, Storage)

```bash
ls -la function_source/
cat function_source/main.py
```

### 3. Másold át a példafájlt
```bash
cp terraform.tfvars.example terraform.tfvars
```

### 4. Szerkeszd a terraform.tfvars-t
```tfvars
user_name   = "Gipsz Jakab"
environment = "demo"
```

⚠️ **FONTOS:** Ugyanazt a `user_name`-t használd, mint az előző step-ekben!

### 5. Terraform inicializálás
```bash
terraform init
```

### 6. Plan (előnézet)
```bash
terraform plan
```

Kimenet: `Plan: 9 to add, 0 to change, 0 to destroy.`

✅ **Ellenőrizd:** Csak **9 ÚJ** resource-ot hoz létre!

### 7. Apply (létrehozás)
```bash
terraform apply
```

⏱️ **Várható idő:** 3-4 perc (Gen2 deployment)

### 8. Ellenőrzés
```bash
terraform output
```

---

## 📤 Outputs
- `csv_export_bucket_name` - CSV export bucket neve (**ÚJ**)
- `csv_exporter_function_name` - CSV exporter function neve (**ÚJ**)
- `csv_exporter_function_url` - CSV exporter function URL (**ÚJ**)
- `scheduler_job_name` - Cloud Scheduler job neve (**ÚJ**)
- `schedule` - Ütemezés (cron formátum) (**ÚJ**)

---

## 🔍 Ellenőrzés GCP Console-ban

### Cloud Function Gen2:
1. GCP Console → **Cloud Functions** (Gen2 címke látszik)
2. Keresd meg: `{your-name}-csv-exporter`
3. **TRIGGER** fül → **Trigger Type:** HTTPS
4. **TRIGGER** fül → **URL:** Ezt hívja a Scheduler
5. **SOURCE** fül → Nézd meg a Python kódot
6. **LOGS** fül → Ide jönnek a function logok
7. **CONFIGURATION** fül:
   - Runtime: Python 3.12
   - Memory: 512 MB
   - Timeout: 300 seconds (5 perc)
   - Environment variables: PROJECT_ID, DATASET_ID, CSV_BUCKET, AGGREGATED_TABLES

### Cloud Scheduler Job:
1. GCP Console → **Cloud Scheduler**
2. Keresd meg: `{your-name}-csv-export-schedule`
3. **Frequency:** `0 * * * *` (óránként)
4. **Timezone:** `Europe/Budapest`
5. **Target:** HTTP
6. **URL:** Cloud Function URL
7. **Last run:** Látod az utolsó futást
8. **Next run:** Következő ütemezett futás

### CSV Export Bucket:
1. GCP Console → **Cloud Storage** → Buckets
2. Keresd meg: `ford-training-430008-{your-name}-csv-exports`
3. Nézd meg a mappákat:
   ```
   monthly_orders_by_ship_mode/
   monthly_orders_us_state/
   monthly_favorite_product/
   monthly_customer_segment_analysis/
   monthly_category_revenue_trend/
   ```
4. Menj be egy mappába → látod a timestamp-es CSV fájlokat
5. **Lifecycle** fül → 30 napos törlési szabály

---

## 🧪 Tesztelés

### 1. Manuális trigger (Scheduler-en keresztül):

```bash
# GCP Console → Cloud Scheduler → Job kiválasztása → RUN NOW gomb
```

Vagy CLI-vel:
```bash
gcloud scheduler jobs run {your-name}-csv-export-schedule \
  --location=europe-west1
```

### 2. Közvetlen function hívás (HTTP-n keresztül):

```bash
# Mentsd el a function URL-t
FUNCTION_URL=$(terraform output -raw csv_exporter_function_url)

# Teszt kérés (Service Account OIDC token-nel)
curl -X POST $FUNCTION_URL \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  -H "Content-Type: application/json"
```

### 3. Ellenőrzés - Function Logs:
```bash
# GCP Console → Cloud Functions → {your-name}-csv-exporter → LOGS
```

Látnod kell:
- ✅ CSV Export Function started
- ✅ Starting export for: monthly_orders_by_ship_mode
- ✅ Table monthly_orders_by_ship_mode loaded: X rows
- ✅ CSV uploaded: gs://...
- ✅ Export completed: 5 successful, 0 failed

### 4. Ellenőrzés - CSV fájlok:

```bash
# Lista az összes CSV-ről
gsutil ls -r gs://ford-training-430008-{your-name}-csv-exports/

# Egy konkrét tábla CSV-jei
gsutil ls gs://ford-training-430008-{your-name}-csv-exports/monthly_orders_by_ship_mode/

# CSV tartalom ellenőrzése
gsutil cat gs://ford-training-430008-{your-name}-csv-exports/monthly_orders_by_ship_mode/2024-01-15_060000.csv | head -20
```

### 5. Ellenőrzés - BigQuery Log Table:

```sql
SELECT 
  timestamp,
  run_id,
  log_level,
  message,
  source,
  additional_info
FROM `{project_id}.{dataset_id}.{your-name}-log-table`
WHERE source = 'csv_exporter'
ORDER BY timestamp DESC
LIMIT 50;
```

Látnod kell:
- ✅ Function started
- ✅ Querying table: monthly_orders_by_ship_mode
- ✅ Table loaded: X rows
- ✅ CSV uploaded: gs://...
- ✅ Export completed

### 6. Ellenőrzés - Scheduler History:

```bash
# GCP Console → Cloud Scheduler → Job → VIEW
```

Látod:
- Execution history (utolsó 20 futás)
- Success/Failure status
- Execution time
- Response codes

---

## 📊 CSV fájlok struktúra

### Bucket mappák:
```
ford-training-430008-{your-name}-csv-exports/
├── monthly_orders_by_ship_mode/
│   ├── 2024-01-15_060000.csv
│   ├── 2024-01-15_070000.csv
│   ├── 2024-01-15_080000.csv
│   └── ...
├── monthly_orders_us_state/
│   ├── 2024-01-15_060000.csv
│   └── ...
├── monthly_favorite_product/
│   └── ...
├── monthly_customer_segment_analysis/
│   └── ...
└── monthly_category_revenue_trend/
    └── ...
```

### Fájlnév formátum:
```
{timestamp}.csv
# pl: 2024-01-15_060000.csv
# Format: YYYY-MM-DD_HHMMSS
```

### CSV tartalom példa (monthly_orders_by_ship_mode):
```csv
year_month,ship_mode,total_sales,order_count
2024-01,First Class,12345.67,89
2024-01,Second Class,23456.78,123
2024-01,Standard Class,34567.89,234
2023-12,First Class,11111.11,78
...
```

---

## 🗑️ Cleanup

**Csak a step-10 resource-ok törlése:**
```bash
terraform destroy
```

⚠️ **Figyelem:** Ez törli:
- CSV export bucket-et (és az összes CSV fájlt!)
- Cloud Function-t
- Cloud Scheduler Job-ot
- IAM binding-okat

Ez NEM törli:
- Service Account (step-02)
- BigQuery Dataset és Tables (step-04, step-08)
- Egyéb step-ek resource-ait

**Csak a CSV fájlok törlése (bucket megtartása):**
```bash
gsutil rm -r gs://ford-training-430008-{your-name}-csv-exports/**
```

---

## 📚 Mit tanultunk?

- ✅ **Data source** használata (8 már létező resource)
- ✅ **Cloud Scheduler** létrehozása és konfigurálása
- ✅ **Cron expression** használata (`0 * * * *`)
- ✅ **Timezone** beállítása (`Europe/Budapest`)
- ✅ **Cloud Functions Gen2** HTTP trigger
- ✅ **OIDC authentication** (Service Account token)
- ✅ **Pandas** CSV export BigQuery-ből
- ✅ **GCS strukturált feltöltés** (mappák + timestamp)
- ✅ **Lifecycle rule** (30 napos retention)
- ✅ **Retry policy** beállítása
- ✅ **Environment variables** átadása function-nek
- ✅ **IAM jogosultságok** Scheduler és Function között
- ✅ Multi-step Terraform projektek

---

## 🔐 IAM & Permissions

### Demo Service Account (step-02-ből):
- ✅ Storage Object Admin (step-05 - eredeti bucket)
- ✅ **Storage Object Admin** (step-10 - **ÚJ**, CSV export bucket)
- ✅ BigQuery Data Editor (step-05 + step-08)
- ✅ **BigQuery Data Viewer** (step-10 - **ÚJ**, aggregált táblák olvasása)
- ✅ BigQuery Job User (step-05)
- ✅ Pub/Sub Publisher (step-06)
- ✅ Pub/Sub Subscriber (step-09)
- ✅ Dataform Editor (step-09)
- ✅ **Cloud Run Invoker** (step-10 - **ÚJ**, Scheduler -> Function)

### Cloud Scheduler (GCP managed):
- Használja a Demo Service Account OIDC token-jét a function híváshoz

---

## ⚠️ Fontos megjegyzések

- **HTTP Trigger:** A function HTTP-n keresztül érhető el (nem Pub/Sub)
- **OIDC Auth:** Cloud Scheduler Service Account token-nel hívja a function-t
- **Pandas export:** Kis adatmennyiségre optimalizált (néhány ezer sor)
- **Memory:** 512 MB elég a Pandas DataFrame-ekhez
- **Timeout:** 5 perc (300 sec) - elég az 5 tábla exportálásához
- **Lifecycle rule:** 30 nap után automatikusan törli a régi CSV-ket
- **Timezone:** Europe/Budapest (CET/CEST)
- **Cron:** `0 * * * *` = minden óra 0. percében (pl. 06:00, 07:00, 08:00...)
- **Bucket struktúra:** Táblanként külön mappa
- **Fájlnév:** Timestamp (YYYY-MM-DD_HHMMSS.csv)
- **BigQuery:** Teljes tábla export (nincs WHERE filter)
- **Ez a step data source-okat használ** - nem hozza létre újra a már létező resource-okat!

---

## 🐛 Troubleshooting

### Scheduler nem indul el:
1. Ellenőrizd az ütemezést: `gcloud scheduler jobs describe {job-name}`
2. Ellenőrizd, hogy a job enabled-e (GCP Console)
3. Nézd meg a Scheduler logs-ot (van-e hiba)

### Function nem válaszol:
1. Ellenőrizd a function deployment status-át
2. Nézd meg a function logs-ot (cold start időt)
3. Ellenőrizd az OIDC token-t (Service Account jogosultság)

### CSV nem jelenik meg a bucket-ben:
1. Ellenőrizd a function logs-ot (BigQuery query, upload hiba)
2. Ellenőrizd a Storage IAM jogosultságokat (objectAdmin)
3. Ellenőrizd a bucket nevet (environment variable)

### "Permission denied" hiba:
1. Demo SA jogosultságok:
   - BigQuery Data Viewer ✅
   - Storage Object Admin (CSV bucket) ✅
   - Cloud Run Invoker ✅
2. Várj 1-2 percet (IAM propagation)

### CSV üres vagy hiányos:
1. Ellenőrizd, hogy a Dataform workflow lefutott-e (step-08)
2. Nézd meg a BigQuery táblák adatait (van-e adat)
3. Ellenőrizd a function logs-ot (row count)

---

## 🎯 **Összefoglalva - Step 10 fájlok:**

```
step-10-scheduled-export/
├── README.md                        ← TE VAGY ITT! 📖
├── providers.tf
├── variables.tf
├── locals.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
└── function_source/
    ├── main.py                      ← CSV export Python kód
    └── requirements.txt             ← Python függőségek
```

---

## ➡️ Következő lépés
👉 **Teljes pipeline tesztelése** (Drive → File Processor → Dataform Trigger → Dataform Workflow → **CSV Export**)

---

## 🎉 Gratulálunk!

Sikeresen létrehoztad az automatikus CSV export rendszert! Most már óránként automatikusan exportálódnak az aggregált táblák CSV formátumba! 🚀📊

**Teljes pipeline:**
1. ✅ File upload → Drive webhook
2. ✅ File Processor → GCS + BigQuery raw_data
3. ✅ Pub/Sub message → Dataform Trigger
4. ✅ Dataform Workflow → Aggregált táblák frissítése
5. ✅ **Cloud Scheduler → CSV Export → GCS** ← **TE VAGY ITT! 🎯**
6. ✅ Minden lépés naplózva BigQuery-ben

**Use case-ek:**
- 📊 Dashboard adatforrás (Looker Studio, Tableau, Power BI)
- 📧 Email mellékletek
- 📤 Külső rendszerek integráció
- 💾 Offline backup
- 📈 Historikus adatok archívum