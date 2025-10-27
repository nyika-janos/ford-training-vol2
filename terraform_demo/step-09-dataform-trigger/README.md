# Step 09: Dataform Workflow Trigger

## 🎯 Cél
Pub/Sub triggered Cloud Function Gen2 létrehozása, ami automatikusan elindítja a Dataform workflow-t, amikor új fájl kerül feldolgozásra.

## ⚠️ **FONTOS: Előfeltételek**

**Step-02, Step-03, Step-04, Step-05, Step-06 ÉS Step-08 resource-ainak létezniük KELL!**

**Step-08 Dataform setup-nak KÉSZ kell lennie!** (Repository + Workspace létrehozva, SQLX fájlok feltöltve)

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

### ÚJ resource-ok (step-09 specifikusak):
- ✅ 1x Storage Bucket (Dataform trigger function forráskódjához)
- ✅ 1x Storage Bucket Object (function ZIP fájl)
- ✅ 1x **Cloud Function Gen2** (Pub/Sub trigger, Python 3.12)
- ✅ 5x IAM Binding (Cloud Run Invoker, SA User, Pub/Sub Subscriber, Dataform Editor)

**Összesen: 8 ÚJ resource**

### Már létező resource-ok (data sources):
- 📌 Service Account (step-02-ből)
- 📌 Storage Bucket - adatok tárolására (step-03-ból)
- 📌 BigQuery Dataset (step-04-ből)
- 📌 BigQuery Log Table (step-04-ből)
- 📌 Pub/Sub Topic (step-06-ból)

---

## 🚀 Cloud Function Gen2 - Pub/Sub Trigger

### Működés:
1. 📥 **Pub/Sub message érkezik** (step-06 file processor küldi)
2. 🔍 **Message feldolgozás** (file_name, rows_loaded kinyerése)
3. 🔨 **Dataform Compilation** (workspace alapján)
4. ▶️ **Dataform Workflow Invocation** (compilation result alapján)
5. 📝 **Logging** (minden lépés a BigQuery log táblába)

### Előnyök:
- ✅ **Automatikus trigger** - nincs manuális workflow indítás
- ✅ **Event-driven** - csak akkor fut, ha új adat érkezik
- ✅ **Retry policy** - újrapróbálkozás hiba esetén
- ✅ **Scalable** - 0-3 instance automatikus scaling
- ✅ **Teljes logging** - minden lépés naplózva

---

## 🔧 Dataform API használat

A function a **Dataform REST API**-t használja:

### 1. Compilation Result létrehozása:
```
POST /v1beta1/projects/{project}/locations/{region}/repositories/{repo}/compilationResults
Body: { "workspace": "projects/.../workspaces/{workspace}" }
```

### 2. Workflow Invocation indítása:
```
POST /v1beta1/projects/{project}/locations/{region}/repositories/{repo}/workflowInvocations
Body: { "compilationResult": "{compilation_name}" }
```

---

## 📝 Lépések

### 1. Navigálj a könyvtárba
```bash
cd step-09-dataform-trigger/
```

### 2. Cloud Function kód ellenőrzése

A `function_source/` könyvtárban találod:
- `main.py` - Dataform trigger Python 3.12 kód
- `requirements.txt` - Python függőségek

```bash
ls -la function_source/
cat function_source/main.py
```

### 3. Másold át a példafájlt
```bash
cp terraform.tfvars.example terraform.tfvars
```

### 4. Szerkeszd a terraform.tfvars-t

⚠️ **FONTOS:** Add meg a Dataform repository és workspace neveket (step-08-ból)!

```tfvars
user_name           = "Gipsz Jakab"
environment         = "demo"
dataform_repository = "your-dataform-repo-name"
dataform_workspace  = "your-workspace-name"
```

**Dataform nevek megtalálása:**
1. GCP Console → **Dataform**
2. Repository neve (pl. `demo-dataform-repo`)
3. Workspace neve (pl. `main-workspace`)

### 5. Terraform inicializálás
```bash
terraform init
```

### 6. Plan (előnézet)
```bash
terraform plan
```

Kimenet: `Plan: 8 to add, 0 to change, 0 to destroy.`

✅ **Ellenőrizd:** Csak **8 ÚJ** resource-ot hoz létre!

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
- `dataform_trigger_function_name` - Dataform trigger function neve (**ÚJ**)
- `pubsub_topic_name` - Figyelt Pub/Sub topic neve (data source, step-06-ból)
- `dataform_repository` - Dataform repository név (**ÚJ**)
- `dataform_workspace` - Dataform workspace név (**ÚJ**)

---

## 🔍 Cloud Function ellenőrzése GCP Console-ban

### Cloud Function Gen2:
1. GCP Console → **Cloud Functions** (Gen2 címke látszik)
2. Keresd meg: `{your-name}-dataform-trigger`
3. **TRIGGER** fül → **Event Type:** `google.cloud.pubsub.topic.v1.messagePublished`
4. **TRIGGER** fül → **Pub/Sub Topic:** `{your-name}-demo-topic-raw`
5. **SOURCE** fül → Nézd meg a Python kódot
6. **LOGS** fül → Ide jönnek a function logok
7. **CONFIGURATION** fül:
   - Runtime: Python 3.12
   - Memory: 256 MB
   - Timeout: 60 seconds
   - Environment variables: PROJECT_ID, DATASET_ID, DATAFORM_REPOSITORY, stb.

### Pub/Sub Subscription:
1. GCP Console → **Pub/Sub** → **Subscriptions**
2. Automatikusan létrejött subscription: `gcf-{function-name}-{region}-{topic-name}`
3. Delivery type: **Push** (Cloud Function-höz)

---

## 🧪 Teljes workflow tesztelése

### 1. Trigger a file processor function-t (step-06):

```bash
# Mentsd el a file processor URL-t
cd ../step-06-cloud-function-processor/
FILE_PROCESSOR_URL=$(terraform output -raw cloud_function_url)

# Teszt kérés (dummy adatokkal)
curl -X POST $FILE_PROCESSOR_URL \
  -H "Content-Type: application/json" \
  -d '{
    "file_id": "test-file-id-123",
    "file_name": "test_superstore.csv"
  }'
```

### 2. Ellenőrzés - File Processor Logs:
```bash
# GCP Console → Cloud Functions → {your-name}-file-processor → LOGS
```

Látnod kell:
- ✅ File processing started
- ✅ Pub/Sub message published

### 3. Ellenőrzés - Dataform Trigger Logs:
```bash
# GCP Console → Cloud Functions → {your-name}-dataform-trigger → LOGS
```

Látnod kell:
- ✅ Dataform Trigger Function started
- ✅ Pub/Sub message received
- ✅ Starting Dataform workflow trigger
- ✅ Compilation created
- ✅ Dataform workflow triggered successfully

### 4. Ellenőrzés - Dataform Workflow:
```bash
# GCP Console → Dataform → Repository → Workflow Invocations
```

Látnod kell:
- ✅ Új workflow invocation (automatikusan indult!)
- ✅ Status: Running → Succeeded
- ✅ Execution graph (5 tábla frissítve)

### 5. Ellenőrzés - BigQuery Log Table:
```sql
SELECT 
  timestamp,
  run_id,
  log_level,
  message,
  source
FROM `{project_id}.{dataset_id}.{your-name}-log-table`
WHERE source = 'dataform_trigger'
ORDER BY timestamp DESC
LIMIT 20;
```

Látnod kell:
- ✅ Function started
- ✅ Pub/Sub message received
- ✅ Compilation created
- ✅ Workflow triggered successfully
- ✅ Function completed

---

## 🔄 Teljes End-to-End Flow

```
1. Google Drive Webhook
   ↓
2. File Processor Function (step-06)
   ├─→ Download file from Drive
   ├─→ Upload to GCS
   ├─→ Load to BigQuery raw_data table
   └─→ Publish Pub/Sub message
       ↓
3. Dataform Trigger Function (step-09) ← TE VAGY ITT! 🎯
   ├─→ Receive Pub/Sub message
   ├─→ Create Dataform compilation
   ├─→ Trigger Dataform workflow
   └─→ Log everything to BigQuery
       ↓
4. Dataform Workflow (step-08)
   ├─→ Refresh monthly_orders_by_ship_mode
   ├─→ Refresh monthly_orders_us_state
   ├─→ Refresh monthly_favorite_product
   ├─→ Refresh monthly_customer_segment_analysis
   └─→ Refresh monthly_category_revenue_trend
       ↓
5. ✅ Aggregált táblák frissítve!
```

---

## 🗑️ Cleanup

**Csak a step-09 resource-ok törlése:**
```bash
terraform destroy
```

Ez NEM törli:
- Service Account (step-02)
- Storage Bucket (step-03)
- BigQuery Dataset és Tables (step-04)
- IAM Bindings (step-05)
- File Processor Function és Pub/Sub (step-06)
- Aggregált táblák és Dataform (step-08)

---

## 📚 Mit tanultunk?

- ✅ **Data source** használata (5 már létező resource)
- ✅ **Cloud Functions Gen2** Pub/Sub trigger
- ✅ **Event-driven architecture** (message → function → workflow)
- ✅ **Dataform REST API** használata
- ✅ **Compilation Result** és **Workflow Invocation** létrehozása
- ✅ **OAuth2 authentication** (google.auth)
- ✅ **Retry policy** beállítása
- ✅ **Environment variables** használata
- ✅ **IAM jogosultságok** Pub/Sub trigger-hez
- ✅ Multi-step Terraform projektek

---

## 🔐 IAM & Permissions

### Demo Service Account (step-02-ből):
- ✅ Storage Object Admin (step-05)
- ✅ BigQuery Data Editor (step-05 + step-08)
- ✅ BigQuery Job User (step-05)
- ✅ Pub/Sub Publisher (step-06)
- ✅ **Pub/Sub Subscriber** (step-09 - **ÚJ**, Pub/Sub message fogadás)
- ✅ **Dataform Editor** (step-09 - **ÚJ**, workflow indítás)
- ✅ **Cloud Run Invoker** (step-09 - **ÚJ**, Gen2 function hívás)
- ✅ **Service Account User** (step-09 - **ÚJ**, SA impersonation)

### Pub/Sub Service Account (GCP managed):
- ✅ **Cloud Run Invoker** (step-09 - **ÚJ**, Gen2 function push trigger)

---

## ⚠️ Fontos megjegyzések

- **Pub/Sub Trigger:** Gen2 function automatikusan létrehoz egy push subscription-t
- **Retry Policy:** `RETRY_POLICY_RETRY` - újrapróbálkozás hiba esetén
- **Dataform API:** REST API használat (Python SDK még nincs)
- **Workspace path:** Teljes path kell (`projects/.../workspaces/...`)
- **Compilation:** Minden workflow előtt új compilation kell
- **Authentication:** OAuth2 token (google.auth.default)
- **Timeout:** 60 másodperc (elég a Dataform API hívásokhoz)
- **Memory:** 256 MB (elég a REST API hívásokhoz)
- **Scaling:** 0-3 instance (event-driven, automatikus)
- **Ez a step data source-okat használ** - nem hozza létre újra a már létező resource-okat!

---

## 🐛 Troubleshooting

### Function nem indul el:
1. Ellenőrizd a Pub/Sub subscription-t (létrejött-e)
2. Ellenőrizd az IAM jogosultságokat (Pub/Sub SA → Cloud Run Invoker)
3. Nézd meg a function logs-ot (van-e hiba)

### Dataform workflow nem indul:
1. Ellenőrizd a `dataform_repository` és `dataform_workspace` neveket
2. Ellenőrizd a Demo SA jogosultságait (Dataform Editor)
3. Nézd meg a function logs-ot (API hiba üzenetek)
4. Ellenőrizd, hogy a workspace létezik-e (GCP Console → Dataform)

### "Permission denied" hiba:
1. Ellenőrizd a Demo SA jogosultságait:
   - Pub/Sub Subscriber ✅
   - Dataform Editor ✅
   - Cloud Run Invoker ✅
2. Várj 1-2 percet (IAM propagation)

---

## 🎯 **Összefoglalva - Step 09 fájlok:**

```
step-09-dataform-trigger/
├── README.md                        ← TE VAGY ITT! 📖
├── providers.tf
├── variables.tf
├── locals.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
└── function_source/
    ├── main.py                      ← Dataform trigger Python kód
    └── requirements.txt             ← Python függőségek
```

---

## ➡️ Következő lépés
👉 **Teljes workflow tesztelése** (Drive → File Processor → Dataform Trigger → Dataform Workflow)

---

## 🎉 Gratulálunk!

Sikeresen létrehoztad az automatikus Dataform trigger-t! Most már minden új fájl feldolgozása után automatikusan frissülnek az aggregált táblák! 🚀📊

**Teljes pipeline:**
1. ✅ File upload → Drive webhook
2. ✅ File Processor → GCS + BigQuery raw_data
3. ✅ Pub/Sub message → Dataform Trigger
4. ✅ Dataform Workflow → Aggregált táblák frissítése
5. ✅ Minden lépés naplózva BigQuery-ben