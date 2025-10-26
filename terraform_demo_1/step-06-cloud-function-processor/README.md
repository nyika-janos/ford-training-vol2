# Step 06: Cloud Function File Processor

## 🎯 Cél
Pub/Sub topic és Cloud Function létrehozása, ami feldolgozza a Drive-ból érkező fájlokat.

## 📦 Mit hozunk létre?
- ✅ 1x Service Account
- ✅ 1x Storage Bucket (adatok tárolására)
- ✅ 1x Storage Bucket (Cloud Function kódjához)
- ✅ 1x BigQuery Dataset
- ✅ 2x BigQuery Tables (log + raw_data)
- ✅ 2x IAM Bindings
- ✅ 1x Pub/Sub Topic
- ✅ 1x Cloud Function (HTTP trigger)

**Összesen: 11 resource**

## 🔧 Funkció működése

A Cloud Function:
1. 📥 Fogadja a HTTP POST kérést (Drive webhook hívja majd)
2. 📁 Letölti a fájlt a Google Drive-ból
3. ☁️ Feltölti a Storage Bucket-be
4. 📊 Betölti a BigQuery raw_data táblába
5. 📝 Minden lépésnél logol a BigQuery log táblába
6. 📢 Pub/Sub üzenetet küld a topic-ra

## 📝 Lépések

### 1. Navigálj a könyvtárba
```bash
cd step-06-cloud-function-processor/
```

### 2. Cloud Function kód előkészítése

A `function_source/` könyvtárban találod:
- `main.py` - Cloud Function kód
- `requirements.txt` - Python függőségek

**Ellenőrizd a fájlokat:**
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

### 5. Terraform inicializálás
```bash
terraform init
```

### 6. Plan (előnézet)
```bash
terraform plan
```

Kimenet: `Plan: 11 to add, 0 to change, 0 to destroy.`

### 7. Apply (létrehozás)
```bash
terraform apply
```

⏱️ **Várható idő:** 2-3 perc (Cloud Function deployment)

### 8. Ellenőrzés
```bash
terraform output
```

## 📤 Outputs
- `service_account_email` - Service Account email
- `bucket_name` - Adatok bucket neve
- `dataset_id` - BigQuery dataset ID
- `log_table_id` - Log tábla ID
- `raw_data_table_id` - Raw data tábla ID
- `pubsub_topic_name` - Pub/Sub topic neve
- `cloud_function_url` - **Cloud Function HTTP URL** (ezt használja majd a Drive webhook!)

## 🔍 Cloud Function ellenőrzése GCP Console-ban

### Cloud Function:
1. GCP Console → Cloud Functions
2. Keresd meg: `{your-name}-file-processor`
3. **TRIGGER** fül → **Trigger URL** (ez az outputs-ban is szerepel)
4. **SOURCE** fül → Nézd meg a Python kódot
5. **LOGS** fül → Ide jönnek a function logok

### Pub/Sub Topic:
1. GCP Console → Pub/Sub → Topics
2. Keresd meg: `{your-name}-demo-topic-raw`

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

## 🗑️ Cleanup
```bash
terraform destroy
```

## 📚 Mit tanultunk?

- ✅ Pub/Sub Topic létrehozása
- ✅ Cloud Function deployment Terraform-mel
- ✅ Cloud Function source code packaging (ZIP)
- ✅ HTTP triggered Cloud Function
- ✅ Service Account használata Cloud Function-ben
- ✅ Multi-resource dependencies
- ✅ Cloud Function logging

## 🔐 IAM & Permissions

A Cloud Function a demo Service Account-tal fut, aminek van:
- ✅ Storage Object Admin (bucket írás)
- ✅ BigQuery Data Editor (BQ írás)
- ✅ (Új) Pub/Sub Publisher (message küldés)

## ⚠️ Fontos megjegyzések

- A Cloud Function **HTTP trigger**-rel rendelkezik (nem auth required - ezt a Drive webhook használja majd)
- A function kód a `function_source/` könyvtárban van
- A Terraform automatikusan ZIP-eli és feltölti a kódot
- A function URL-t használjuk majd a Step-07-ben (Drive webhook regisztráció)

## ➡️ Következő lépés
👉 `step-07-drive-registration/` - Drive webhook beállítás a function URL-lel
