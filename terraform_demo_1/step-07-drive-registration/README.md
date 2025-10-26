# Step 07: Google Drive Push Notifications (Webhook)

## 🎯 Cél
Valódi Drive API Push Notification webhook beállítása, ami értesíti a Cloud Function-t minden Drive változásról.

## ⚠️ **Hogyan működik?**

1. **Webhook regisztráció** - Regisztráljuk a Cloud Function URL-t a Drive API-nál
2. **Drive értesítések** - A Drive minden változásról POST request-et küld
3. **Function szűrés** - A Cloud Function szűri a változásokat és csak a releváns fájlokat dolgozza fel

**Előny:** Valós idejű értesítések, nincs polling  
**Hátrány:** 24 órán belül újra kell regisztrálni (expire)

---

## 📦 Előfeltételek

**Step-06 Cloud Function-nek futnia KELL!**

```bash
cd ../step-06-cloud-function-processor/
terraform apply
```

---

## 🔧 **Drive Channel Regisztráció - Lépésről Lépésre**

### **1. Service Account kulcs generálása**

A demo Service Account-hoz (amit a Terraform létrehozott step-02-ben):

**GCP Console:**
1. Navigálj: **IAM & Admin** → **Service Accounts**
2. Keresd meg: `terraform-demo-sa-{your-name}@ford-training-430008.iam.gserviceaccount.com`
3. Kattints a Service Account-ra
4. **KEYS** fül → **ADD KEY** → **Create new key**
5. Válaszd: **JSON**
6. **CREATE** → A kulcs letöltődik (`terraform-demo-sa-*-key.json`)

---

### **2. Google Drive API engedélyezése**

**GCP Console:**
1. **APIs & Services** → **Library**
2. Keresd meg: `Google Drive API`
3. Kattints rá
4. **ENABLE**

---

### **3. Drive folder létrehozása és megosztása**

**Google Drive-ban:**

1. **Hozz létre egy új foldert:**
   - Név: `Terraform Demo Upload` (vagy bármi más)

2. **Oszd meg a Service Account-tal:**
   - Jobb klikk a folderön → **Share**
   - Add hozzá az email címet:
     ```
     terraform-demo-sa-{your-name}@ford-training-430008.iam.gserviceaccount.com
     ```
   - Jogosultság: **Viewer** (elég, mert csak olvasni fog)
   - **Share**

3. **Másold ki a folder ID-t:**
   - Nyisd meg a foldert
   - URL-ből:
     ```
     https://drive.google.com/drive/folders/1a2b3c4d5e6f7g8h9i0j
                                             ^^^^^^^^^^^^^^^^^^^^
                                             Ez a folder ID
     ```

---

### **4. CloudShell előkészítés**

**CloudShell-ben:**

```bash
# Navigálj a step-07 könyvtárba
cd ~/ford-training-vol2/terraform_demo_1/step-07-drive-webhook/

# Ellenőrizd a fájlokat
ls -la
```

**Töltsd fel a Service Account kulcsot:**
- CloudShell-ben: három pont menü → **Upload file**
- Válaszd ki: `terraform-demo-sa-*-key.json`
- Nevezd át: `demo-sa-key.json`

```bash
# Ellenőrizd
ls -la demo-sa-key.json
```

---

### **5. Python függőségek telepítése**

```bash
pip3 install --user -r requirements.txt
```

**Ellenőrzés:**
```bash
pip3 list | grep google
```

Látnod kell:
- `google-auth`
- `google-api-python-client`

---

### **6. Környezeti változók beállítása**

**Másold át a példafájlt:**
```bash
cp .env.example .env
```

**Szerkeszd:**
```bash
nano .env
```

**Töltsd ki:**
```env
# Cloud Function URL (step-06 terraform output)
FUNCTION_URL=https://europe-west1-ford-training-430008.cloudfunctions.net/henry-ford-file-processor

# Service Account key file name
SA_KEY_FILE=demo-sa-key.json

# Optional security token
WEBHOOK_TOKEN=my-secret-token-123
```

**Mentés:** Ctrl+O, Enter, Ctrl+X

**Cloud Function URL megszerzése:**
```bash
cd ../step-06-cloud-function-processor/
terraform output -raw cloud_function_url
```

Másold be ezt az URL-t a `.env` fájlba!

---

### **7. Step-06 frissítése a monitored_folder_id-val**

**Szerkeszd a terraform.tfvars-t:**
```bash
cd ../step-06-cloud-function-processor/
nano terraform.tfvars
```

**Add hozzá a folder ID-t:**
```tfvars
user_name   = "Henry Ford"
environment = "demo"

# Drive folder ID (amit megosztottál a SA-val)
monitored_folder_id = "1a2b3c4d5e6f7g8h9i0j"
```

**Futtasd újra a Terraform-et:**
```bash
terraform apply
```

Ez frissíti a Cloud Function environment variables-t a folder ID-val.

---

### **8. Webhook regisztráció futtatása**

```bash
cd ../step-07-drive-webhook/
python3 register_webhook.py
```

**Sikeres kimenet:**
```
🚀 Registering Drive Push Notification webhook...
📍 Webhook URL: https://europe-west1-ford-training-430008.cloudfunctions.net/henry-ford-file-processor
🔑 Channel ID: 12345678-1234-1234-1234-123456789abc
⏰ Expiration: 2025-01-16T15:30:00

✅ Webhook registered successfully!

📋 Response:
{
  "kind": "api#channel",
  "id": "12345678-1234-1234-1234-123456789abc",
  "resourceId": "abcdefghijklmnopqrstuvwxyz",
  "resourceUri": "https://www.googleapis.com/drive/v3/changes?...",
  "expiration": "1705417800000"
}

💾 Channel info saved to: channel_info.json
⚠️  Save this file! You'll need it to stop the webhook.

🎉 Done! Drive will now send notifications to your Cloud Function.
⏰ Webhook will expire in 23 hours (at 2025-01-16T15:30:00)
🔄 Re-run this script before expiration to renew the webhook.
```

**Ha hibát kapsz:**

❌ **Error 403: Permission denied**
- Ellenőrizd, hogy a Drive API engedélyezve van-e
- Ellenőrizd, hogy a SA kulcs helyes-e

❌ **Error 400: Invalid webhook URL**
- Ellenőrizd, hogy a Cloud Function URL helyes-e
- Ellenőrizd, hogy a Function nyilvánosan elérhető-e (`allUsers` invoker role)

---

### **9. Tesztelés**

**Töltsd fel egy CSV fájlt a Drive folderbe:**

1. Nyisd meg a `Terraform Demo Upload` foldert
2. Töltsd fel: `superstore_final_dataset_1.csv`

**Ellenőrzés CloudShell-ben:**

```bash
# Cloud Function logs
gcloud functions logs read henry-ford-file-processor \
  --region=europe-west1 \
  --limit=50
```

**Vagy GCP Console-ban:**
- Cloud Functions → `henry-ford-file-processor` → LOGS fül

**Kimenet (példa):**
```
Drive notification received
Found 1 recent changes
Processing file from Drive notification: superstore_final_dataset_1.csv
Downloading file from Google Drive...
File downloaded: superstore_final_dataset_1.csv
Uploading file to Cloud Storage...
File uploaded to GCS: gs://ford-training-430008-henry-ford-demo-bucket/superstore_final_dataset_1.csv
Loading data to BigQuery...
Data loaded to BigQuery: 9994 rows
Publishing Pub/Sub message...
Pub/Sub message published
File processing completed successfully: superstore_final_dataset_1.csv
Drive notification processed: 1 files
```

---

### **10. BigQuery ellenőrzés**

```bash
# Log tábla
bq query --use_legacy_sql=false '
SELECT timestamp, log_level, message 
FROM `ford-training-430008.henry_ford_demo_dataset.henry-ford-log-table` 
ORDER BY timestamp DESC 
LIMIT 20
'

# Raw data tábla
bq query --use_legacy_sql=false '
SELECT COUNT(*) as row_count 
FROM `ford-training-430008.henry_ford_demo_dataset.henry-ford-raw-data-table`
'
```

---

### **11. Webhook leállítása (opcionális)**

**Ha le akarod állítani a webhook-ot:**

```bash
python3 stop_webhook.py
```

**Kimenet:**
```
🛑 Stopping webhook...
🔑 Channel ID: 12345678-1234-1234-1234-123456789abc
📍 Resource ID: abcdefghijklmnopqrstuvwxyz

✅ Webhook stopped successfully!
💾 channel_info.json removed
```

---

## 📊 **Összefoglalás: Teljes folyamat**

```
1. Service Account kulcs generálás (GCP Console)
   ↓
2. Drive API engedélyezés (GCP Console)
   ↓
3. Drive folder létrehozás és megosztás SA-val (Google Drive)
   ↓
4. Kulcs feltöltés CloudShell-be
   ↓
5. Python függőségek telepítése (pip)
   ↓
6. .env fájl kitöltése (FUNCTION_URL, SA_KEY_FILE)
   ↓
7. Step-06 terraform.tfvars frissítése (monitored_folder_id)
   ↓
8. terraform apply (Cloud Function environment update)
   ↓
9. python3 register_webhook.py (Channel regisztráció)
   ↓
10. CSV fájl feltöltés Drive-ba (Teszt)
    ↓
11. Ellenőrzés (Logs, BigQuery)
```

---

## ⏰ **Fontos: Webhook expiration**

A webhook **23 óra után lejár**!

**Megújítás:**
```bash
# Opcionálisan leállítod a régit (ha még él)
python3 stop_webhook.py

# Újra regisztrálod
python3 register_webhook.py
```

**Automatizálás (opcionális):**
- Cloud Scheduler job: 22 órán belül újra hívja a regisztrációs script-et
- Cron job CloudShell-ben (ha folyamatosan fut)

---

## 📚 **Mit tanultunk?**

- ✅ Google Drive API Push Notifications
- ✅ Webhook regisztráció és kezelés
- ✅ Channel lifecycle (expiration)
- ✅ Cloud Function notification handling
- ✅ Drive changes API
- ✅ Folder-based filtering

---

## 🔐 **Biztonsági megjegyzések**

- A webhook URL nyilvános, de:
  - Opcionális `token` headerrel védhető
  - A Cloud Function szűri a forrást
  - Csak CSV fájlokat dolgoz fel
  - Csak a monitored folder-ből

- A `demo-sa-key.json` érzékeny adat!
  - NE commitold Git-be (`.gitignore`-ban van)
  - Training után törölheted a kulcsot
  - Production-ben használj Workload Identity-t

---

## ⚠️ **Fontos tudnivalók**

- **Expiration:** Max 24 óra (domain-wide delegation nélkül)
- **Notification delay:** Néhány másodperc
- **Changes API limit:** 100,000 kérés/nap/user
- **Filtering:** A Function-ben történik, nem a registration-nél

---

## 🎯 **Production tippek**

- Használj **domain-wide delegation**-t hosszabb expiration-höz (1 hét)
- Tárold a **pageToken**-t, hogy ne veszíts el változásokat
- Használj **Cloud Scheduler**-t auto-renewal-hez
- Használj **Firestore**-t a channel state tárolásához
- Monitorozd az **expiration**-t és küldj alertet

---

## ➡️ **Eredmény**

Most már **valós időben** reagál a rendszer a Drive-ba feltöltött fájlokra! 🎉

Új fájl érkezik → Drive értesíti a Function-t → Automatikus feldolgozás → GCS + BigQuery + Pub/Sub ✅
