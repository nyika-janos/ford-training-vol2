# Step 06: Cloud Function Gen2 File Processor

## 🎯 Cél
Pub/Sub topic és **Cloud Function Gen2** létrehozása, ami feldolgozza a Drive-ból érkező fájlokat.

## ⚠️ **FONTOS: Előfeltételek**

**Step-02, Step-03, Step-04 ÉS Step-05 resource-ainak létezniük KELL!**

Ha még nem futtattad le őket sorrendben:
```bash
cd ../step-02-service-account/ && terraform apply
cd ../step-03-storage/ && terraform apply
cd ../step-04-bigquery/ && terraform apply
cd ../step-05-iam/ && terraform apply
```

**NE futtass `terraform destroy`-t az előző step-ekben!**

---

## 📦 Mit hoz létre ez a step?

### ÚJ resource-ok (step-06 specifikusak):
- ✅ 1x Pub/Sub Topic
- ✅ 1x Pub/Sub Publisher IAM Binding (PROJECT szintű)
- ✅ 1x Storage Bucket (Cloud Function forráskódjához)
- ✅ 1x Storage Bucket Object (function ZIP fájl)
- ✅ 1x **Cloud Function Gen2** (HTTP trigger, Python 3.12)
- ✅ 1x Cloud Run Service IAM Binding (Gen2 invoker)

**Összesen: 6 ÚJ resource**

### Már létező resource-ok (data sources):
- 📌 Service Account (step-02-ből)
- 📌 Storage Bucket - adatok tárolására (step-03-ból)
- 📌 BigQuery Dataset (step-04-ből)
- 📌 BigQuery Log Table (step-04-ből)
- 📌 BigQuery Raw Data Table (step-04-ből)

---

## 🚀 Cloud Function Gen2 Előnyök

- ✅ **Cloud Run alapú** - modernebb architektúra
- ✅ **Python 3.12** - legújabb Python verzió
- ✅ **Hosszabb timeout** - max 60 perc (Gen1: 9 perc)
- ✅ **Több memória** - akár 32GB (Gen1: 8GB)
- ✅ **Jobb scaling** - 0-1000 instance
- ✅ **Gyorsabb cold start**

---

## 🔧 Funkció működése

A Cloud Function:
1. 📥 Fogadja a HTTP POST kérést (Drive webhook hívja majd)
2. 📁 Letölti a fájlt a Google Drive-ból
3. ☁️ Feltölti a Storage Bucket-be
4. 📊 Betölti a BigQuery raw_data táblába
5. 📝 Minden lépésnél logol a BigQuery log táblába
6. 📢 Pub/Sub üzenetet küld a topic-ra

---

## 📝 Lépések

### 1. Navigálj a könyvtárba
```bash
cd step-06-cloud-function-processor/
```

### 2. Cloud Function kód ellenőrzése

A `function_source/` könyvtárban találod:
- `main.py` - Cloud Function Python 3.12 kód
- `requirements.txt` - Frissített Python függőségek

```bash
ls -la function_source/
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

Kimenet: `Plan: 6 to add, 0 to change, 0 to destroy.`

✅ **Ellenőrizd:** Csak **6 ÚJ** resource-ot hoz létre!

### 7. Apply (létrehozás)
```bash
terraform apply
```

⏱️ **Várható idő:** 3-4 perc (Gen2 deployment lassabb mint Gen1)

### 8. 🔓 **MANUÁLIS LÉPÉS: Unauthenticated hozzáférés engedélyezése**

⚠️ **FONTOS:** A Google Drive webhook **nem küld authentication header-t**, ezért a function-t **unauthenticated** módba kell állítani.

**GCP Console-ban:**
1. GCP Console → **Cloud Functions**
2. Keresd meg: `{your-name}-file-processor`
3. Kattints rá → **EDIT** gomb (felül)
4. Görgess le a **SECURITY** részhez
5. **Authentication:** Válaszd az **"Allow unauthenticated invocations"** opciót
6. Kattints a **NEXT** gombra (alul)
7. Kattints a **DEPLOY** gombra

✅ Most már a Drive webhook hívhatja authentication nélkül!

**Miért kell ez?**
- A Terraform `allUsers` jogot ad Cloud Run Invoker-nek
- DE ez még mindig "Authentication Required" módot eredményez
- A Drive webhook nem tud OAuth token-t küldeni
- Ezért manuálisan kell átállítani "Unauthenticated"-re

### 9. Ellenőrzés
```bash
terraform output
```

---

## 📤 Outputs
- `service_account_email` - Service Account email (data source, step-02-ből)
- `bucket_name` - Adatok bucket neve (data source, step-03-ból)
- `dataset_id` - BigQuery dataset ID (data source, step-04-ből)
- `log_table_id` - Log tábla ID (data source, step-04-ből)
- `raw_data_table_id` - Raw data tábla ID (data source, step-04-ből)
- `pubsub_topic_name` - Pub/Sub topic neve (**ÚJ**)
- `cloud_function_url` - **Cloud Function Gen2 HTTPS URL** (**ÚJ** - ezt használja majd a Drive webhook!)

---

## 🔍 Cloud Function ellenőrzése GCP Console-ban

### Cloud Function Gen2:
1. GCP Console → **Cloud Functions** (Gen2 címke látszik)
2. Keresd meg: `{your-name}-file-processor`
3. **TRIGGER** fül → **TRIGGER URL** (ez az outputs-ban is szerepel)
4. **SECURITY** fül → Ellenőrizd: **"Allow unauthenticated invocations"** ✅
5. **SOURCE** fül → Nézd meg a Python kódot
6. **LOGS** fül → Ide jönnek a function logok
7. **METRICS** fül → Gen2 metrics (invocations, memory, CPU)

### Pub/Sub Topic:
1. GCP Console → Pub/Sub → Topics
2. Keresd meg: `{your-name}-demo-topic-raw`

---

## 🧪 Tesztelés (manuális)

**Teszt HTTP kérés küldése:**

```bash
# Mentsd el a function URL-t
FUNCTION_URL=$(terraform output -raw cloud_function_url)

# Teszt kérés (dummy adatokkal)
curl -X POST $FUNCTION_URL \
  -H "Content-Type: application/json" \
  -d '{
    "file_id": "test-file-id",
    "file_name": "test.csv"
  }'
```

**Ellenőrzés:**
- Cloud Function Logs → látszódik a hívás
- BigQuery log tábla → új log bejegyzések

---

## 🗑️ Cleanup

**Csak a step-06 resource-ok törlése:**
```bash
terraform destroy
```

Ez NEM törli:
- Service Account (step-02)
- Storage Bucket (step-03)
- BigQuery Dataset és Tables (step-04)
- IAM Bindings (step-05)

---

## 📚 Mit tanultunk?

- ✅ **Data source** használata
- ✅ **Cloud Functions Gen2** deployment
- ✅ **Python 3.12** használata
- ✅ Cloud Run IAM binding (Gen2 alapú)
- ✅ Pub/Sub Topic létrehozása
- ✅ Function source code packaging (ZIP)
- ✅ **Unauthenticated access** beállítása (manuális lépés)
- ✅ Multi-step Terraform projektek

---

## 🔐 IAM & Permissions

A Cloud Function a demo Service Account-tal fut, aminek már van (step-05-ből):
- ✅ Storage Object Admin (bucket írás)
- ✅ BigQuery Data Editor (BQ írás)

És most hozzáadtuk (step-06-ban):
- ✅ **Pub/Sub Publisher** (PROJECT szintű - message küldés)
- ✅ **Cloud Run Invoker** (Gen2 function hívás - allUsers)
- ✅ **Unauthenticated invocations** (manuálisan beállítva - Drive webhook-hoz)

---

## ⚠️ Fontos megjegyzések

- **Cloud Functions Gen2** használ (Cloud Run alapú)
- **Python 3.12** runtime
- A function **HTTP trigger**-rel rendelkezik
- **Unauthenticated access:** Manuálisan kell beállítani (8. lépés)! ⚠️
- Gen2 IAM: **Cloud Run Service IAM** (nem Cloud Functions IAM)
- A Terraform automatikusan ZIP-eli és feltölti a kódot
- A function URL-t használjuk majd a Step-07-ben (Drive webhook regisztráció)
- **Ez a step data source-okat használ** - nem hozza létre újra a már létező resource-okat!

---

## ➡️ Következő lépés
👉 `step-07-drive-registration/` - Drive webhook beállítás a function URL-lel

---

## 🎯 **Összefoglalva - Step 06 fájlok:**

```
step-06-cloud-function-processor/
├── README.md
├── providers.tf
├── variables.tf
├── locals.tf
├── main.tf            ← BŐVÜLT (Minden + Pub/Sub topic, Cloud Function)
├── outputs.tf
├── terraform.tfvars.example
└── function_source/
    ├── main.py
    └── requirements.txt