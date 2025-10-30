# Step 11: CSV Browser Website (Cloud Run)

## 🎯 Cél
Flask webes alkalmazás létrehozása Cloud Run-on, amely lehetővé teszi a step-10-ben exportált CSV fájlok böngészését és letöltését.

## ⚠️ **FONTOS: Előfeltételek**

**Step-02, Step-03, Step-04, Step-05, Step-06, Step-08, Step-09 ÉS Step-10 resource-ainak létezniük KELL!**

**Step-10 CSV export-nak FUTNIA KELLETT!** (Van adat a CSV export bucket-ben)

Ha még nem futtattad le őket sorrendben:
```bash
cd ../step-02-service-account/ && terraform apply
cd ../step-03-storage/ && terraform apply
cd ../step-04-bigquery/ && terraform apply
cd ../step-05-iam/ && terraform apply
cd ../step-06-cloud-function-processor/ && terraform apply
cd ../step-08-dataform/ && terraform apply
cd ../step-09-dataform-trigger/ && terraform apply
cd ../step-10-scheduled-export/ && terraform apply
```

**NE futtass `terraform destroy`-t az előző step-ekben!**

---

## 📦 Mit hoz létre ez a step?

### ÚJ resource-ok (step-11 specifikusak):
- ✅ 1x Cloud Run Service (Flask web app, Python 3.11)
- ✅ 2x IAM Binding (Cloud Run Invoker - allUsers, Storage Viewer - SA)

**Összesen: 3 ÚJ resource**

### Manuális lépés (Terraform előtt):
- 🔨 Docker image build és push (gcr.io vagy Artifact Registry)

### Manuális lépés (Terraform után):
- 🔓 Unauthenticated access beállítása (GCP Console-ban)

### Már létező resource-ok (data sources):
- 📌 Service Account (step-02-ből)
- 📌 CSV Export Bucket (step-10-ből)

---

## 🌐 Webes alkalmazás funkciói

### Funkciók:
- ✅ **Mappa böngészés** - Navigálás a bucket struktúrában
- ✅ **CSV fájlok listázása** - Időbélyeg, méret, utolsó módosítás
- ✅ **Letöltés** - Direct stream a bucket-ből
- ✅ **Breadcrumb navigáció** - Könnyű vissza navigálás
- ✅ **Bootstrap UI** - Responsive dizájn
- ✅ **Public access** - Nincs authentication szükséges

### Technológiák:
- **Backend:** Flask (Python 3.11)
- **Frontend:** Bootstrap 5 + Bootstrap Icons
- **Hosting:** Cloud Run (serverless, auto-scaling)
- **Auth:** Service Account (demo SA, step-02-ből)

---

## 📝 Lépések

### 1. Navigálj a könyvtárba
```bash
cd step-11-website/
```

### 2. Ellenőrizd a csv-browser alkalmazást

```bash
ls -la csv-browser/
```

Látnod kell:
- `Dockerfile`
- `app.py`
- `requirements.txt`
- `templates/index.html`

### 3. 🔨 **MANUÁLIS LÉPÉS: Docker image build & push**

**A Terraform NEM tudja automatikusan build-elni a Docker image-t**, ezért ezt manuálisan kell megtenni.

#### 3a. Build & Push gcr.io-ba (Google Container Registry):

```bash
# Navigálj a csv-browser könyvtárba
cd csv-browser/

# Szerezd meg a user_name-t (pl. henry-ford)
USER_NAME="henry-ford"  # ⚠️ CSERÉLD KI A SAJÁTODRA!

# Docker image build
docker build -t gcr.io/ford-training-430008/${USER_NAME}-csv-browser:latest .

# Docker image push (szükséges lehet: gcloud auth configure-docker)
docker push gcr.io/ford-training-430008/${USER_NAME}-csv-browser:latest

# Vissza a step-11 könyvtárba
cd ..
```

**Vagy használd a gcloud builds submit-ot** (Cloud Build):

```bash
cd csv-browser/

USER_NAME="henry-ford"  # ⚠️ CSERÉLD KI!

gcloud builds submit \
  --tag gcr.io/ford-training-430008/${USER_NAME}-csv-browser:latest \
  --project ford-training-430008

cd ..
```

✅ **Ez a könnyebb!** Nem kell lokális Docker.

#### 3b. Ellenőrizd, hogy létrejött-e az image:

```bash
gcloud container images list --repository=gcr.io/ford-training-430008

# Részletek
gcloud container images describe gcr.io/ford-training-430008/${USER_NAME}-csv-browser:latest
```

### 4. Másold át a példafájlt

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 5. Szerkeszd a terraform.tfvars-t

```tfvars
user_name   = "Henry Ford"
environment = "demo"

# (Opcionális) Ha custom image URL-t akarsz
# docker_image = "gcr.io/ford-training-430008/henry-ford-csv-browser:latest"
```

⚠️ **FONTOS:** Ugyanazt a `user_name`-t használd, mint az előző step-ekben!

### 6. Terraform inicializálás

```bash
terraform init
```

### 7. Plan (előnézet)

```bash
terraform plan
```

Kimenet: `Plan: 3 to add, 0 to change, 0 to destroy.`

✅ **Ellenőrizd:** Csak **3 ÚJ** resource-ot hoz létre!

### 8. Apply (létrehozás)

```bash
terraform apply
```

⏱️ **Várható idő:** 1-2 perc (Cloud Run deployment)

### 9. 🔓 **MANUÁLIS LÉPÉS: Unauthenticated hozzáférés engedélyezése**

⚠️ **FONTOS:** A Terraform `allUsers` jogot ad Cloud Run Invoker-nek, DE ez még mindig **"Authentication Required"** módot eredményez. A webes böngésző **nem küld authentication header-t**, ezért a service-t **unauthenticated** módba kell állítani.

**GCP Console-ban:**
1. GCP Console → **Cloud Run**
2. Keresd meg: `{your-name}-csv-browser`
3. Kattints rá → **EDIT** gomb (felül, a deploy gomb mellett)
4. Görgess le a **SECURITY** részhez
5. **Authentication:** Válaszd az **"Allow public access"** opciót ✅
6. Kattints a **DEPLOY** gombra (alul)

⏱️ Várj ~30 másodpercet a deployment-re.

✅ Most már bárki hozzáférhet authentication nélkül!

**Miért kell ez?**
- A Terraform `allUsers` jogot ad Cloud Run Invoker-nek
- DE ez még mindig "Authentication Required" módot eredményez
- A böngésző nem tud OAuth token-t küldeni
- Ezért manuálisan kell átállítani "Unauthenticated"-re

**Ellenőrzés:**
- GCP Console → Cloud Run → Service → **SECURITY** fül
- **Authentication:** "Allow public access" ✅

### 10. Ellenőrzés

```bash
terraform output
```

Kimenet:
```
cloud_run_url = "https://henry-ford-csv-browser-XXXXX-ew.a.run.app"
```

### 🎉 11. Nyisd meg a webes alkalmazást!

```bash
# Másolod ki az URL-t
CLOUD_RUN_URL=$(terraform output -raw cloud_run_url)
echo $CLOUD_RUN_URL

# Vagy megnyitod böngészőben
open $CLOUD_RUN_URL  # macOS
xdg-open $CLOUD_RUN_URL  # Linux
```

**Vagy egyszerűen:** Copy-paste az URL-t a böngészőbe! 🌐

---

## 📤 Outputs

- `cloud_run_url` - CSV Browser website URL (**ÚJ** - ezt nyisd meg!)
- `service_name` - Cloud Run service neve (**ÚJ**)
- `docker_image` - Docker image URL (**ÚJ**)
- `csv_bucket_name` - CSV export bucket neve (data source, step-10-ből)

---

## 🔍 Cloud Run ellenőrzése GCP Console-ban

### Cloud Run Service:
1. GCP Console → **Cloud Run**
2. Keresd meg: `{your-name}-csv-browser`
3. **URL:** Kattints rá → megnyílik a webes alkalmazás
4. **SECURITY** fül → Ellenőrizd: **"Allow public access"** ✅
5. **REVISIONS** fül → Látod az aktív revision-t
6. **METRICS** fül → Request count, latency, errors
7. **LOGS** fül → Alkalmazás logok
8. **YAML** fül → Service konfiguráció

### Webes alkalmazás használata:
1. Főoldal → Látod a mappákat (pl. `monthly_orders_by_ship_mode`)
2. Kattints egy mappára → Látod a CSV fájlokat időbélyegekkel
3. Kattints "Letöltés" gombra → Letöltődik a CSV
4. Breadcrumb navigáció → Vissza a főoldalra vagy szülő mappába

---

## 🧪 Tesztelés

### 1. Webes felület tesztelése:

**URL megnyitása:**
```bash
terraform output -raw cloud_run_url | xargs open  # macOS
```

**Funkciók ellenőrzése:**
- ✅ Főoldal betöltődik
- ✅ Látszanak a mappák (5 db)
- ✅ Mappa megnyitása → CSV fájlok listázása
- ✅ Fájl letöltése → CSV file letöltődik
- ✅ Breadcrumb navigáció működik

### 2. Cloud Run logs ellenőrzése:

```bash
gcloud run services logs read ${YOUR_NAME}-csv-browser \
  --region=europe-west1 \
  --limit=50
```

Látnod kell:
```
INFO:app:=== APP STARTED ===
INFO:app:PROJECT_ID: ford-training-430008
INFO:app:BUCKET_NAME: ford-training-430008-henry-ford-csv-exports
INFO:app:Storage client initialized successfully
INFO:app:=== INDEX route called ===
INFO:app:Total blobs found: XX
INFO:app:Result: 5 folders, 0 files
```

### 3. Docker image ellenőrzése:

```bash
gcloud container images list --repository=gcr.io/ford-training-430008
gcloud container images describe gcr.io/ford-training-430008/${YOUR_NAME}-csv-browser:latest
```

### 4. Authentication teszt:

```bash
# Próbáld meg curl-lal (authentication nélkül)
curl -I $(terraform output -raw cloud_run_url)

# Ha 200 OK → működik az unauthenticated access! ✅
# Ha 403 Forbidden → még nincs beállítva (lásd 9. lépés) ❌
```

---

## 🗑️ Cleanup

**Csak a step-11 resource-ok törlése:**
```bash
terraform destroy
```

Ez NEM törli:
- Docker image-t (gcr.io-ban marad)
- Service Account (step-02)
- CSV Export Bucket (step-10)
- Egyéb step-ek resource-ait

**Docker image törlése** (opcionális):
```bash
gcloud container images delete gcr.io/ford-training-430008/${YOUR_NAME}-csv-browser:latest --quiet
```

---

## 📚 Mit tanultunk?

- ✅ **Data source** használata (2 már létező resource)
- ✅ **Docker image** build és push (GCR)
- ✅ **Cloud Run** service deployment Terraform-mal
- ✅ **Flask** web alkalmazás Cloud Run-on
- ✅ **Google Cloud Storage SDK** Python-ból
- ✅ **IAM public access** beállítása (allUsers)
- ✅ **Unauthenticated access** beállítása (manuális lépés)
- ✅ **Environment variables** Cloud Run-ban
- ✅ **Service Account** használata Cloud Run-ban
- ✅ **Streaming file download** Flask-ból
- ✅ **Bootstrap UI** responsive dizájn
- ✅ Multi-step Terraform projektek

---

## 🔐 IAM & Permissions

### Demo Service Account (step-02-ből):
- ✅ Storage Object Admin (step-05 - eredeti bucket)
- ✅ Storage Object Admin (step-10 - CSV export bucket - step-10-ből)
- ✅ **Storage Object Viewer** (step-11 - **ÚJ**, CSV bucket read-only)
- ✅ BigQuery Data Editor (step-05 + step-08)
- ✅ BigQuery Data Viewer (step-10)
- ✅ BigQuery Job User (step-05)
- ✅ Pub/Sub Publisher (step-06)
- ✅ Pub/Sub Subscriber (step-09)
- ✅ Dataform Editor (step-09)
- ✅ Cloud Run Invoker (step-10)

### Cloud Run Service:
- ✅ **Cloud Run Invoker** (step-11 - **ÚJ**, allUsers - public access)
- ✅ **Unauthenticated invocations** (manuálisan beállítva - webes hozzáféréshez)

---

## ⚠️ Fontos megjegyzések

- **Docker image:** Manuálisan kell build-elni és push-olni a Terraform előtt
- **Unauthenticated access:** Manuálisan kell beállítani a Terraform után (9. lépés)! ⚠️
- **gcr.io:** Google Container Registry (régebbi, de egyszerűbb)
- **Artifact Registry:** Újabb, jobban integrált, de több setup kell
- **Service Account:** A demo SA-t használjuk (már van storage joga)
- **Public access:** allUsers + unauthenticated = nincs authentication
- **No signed URL:** Direct streaming Flask-ból (nem kell private key)
- **Auto-scaling:** 0-10 instance (serverless)
- **Cold start:** Első kérés lassabb lehet (~2-3 sec)
- **Costs:** Pay-per-request (első 2M request/hó ingyen)
- **Ez a step data source-okat használ** - nem hozza létre újra a már létező resource-okat!

---

## 🐛 Troubleshooting

### Docker build failed:
```bash
# Ellenőrizd a Dockerfile szintaxist
# Ellenőrizd a requirements.txt verziókat
# Nézd meg a build logs-ot
```

### Docker push permission denied:
```bash
# Configure docker auth
gcloud auth configure-docker

# Vagy használd a Cloud Build-et
gcloud builds submit --tag gcr.io/...
```

### Cloud Run deployment failed:
```bash
# Ellenőrizd, hogy az image létezik-e
gcloud container images list

# Ellenőrizd a Cloud Run logs-ot
gcloud run services logs read ${SERVICE_NAME} --region=europe-west1
```

### "403 Forbidden" hiba a webes alkalmazásban:
⚠️ **A leggyakoribb hiba!**

**Megoldás:** Állítsd be az "Unauthenticated invocations" opciót (9. lépés)!

```bash
# Ellenőrizd curl-lal
curl -I $(terraform output -raw cloud_run_url)

# Ha 403 → nincs beállítva az unauthenticated access
# Lásd: 9. lépés (SECURITY → "Allow public access")
```

### Webes alkalmazás üres (nincs fájl):
```bash
# Ellenőrizd, hogy van-e adat a bucket-ben
gsutil ls -r gs://ford-training-430008-${YOUR_NAME}-csv-exports/

# Futtasd le a step-10 export function-t
cd ../step-10-scheduled-export/
FUNCTION_URL=$(terraform output -raw csv_exporter_function_url)
curl -X POST $FUNCTION_URL -H "Authorization: Bearer $(gcloud auth print-identity-token)"
```

### "Permission denied" hiba (storage):
```bash
# Ellenőrizd a demo SA jogosultságait
# Ellenőrizd a bucket IAM-ját
gsutil iam get gs://ford-training-430008-${YOUR_NAME}-csv-exports/
```

### Letöltés nem működik:
```bash
# Ellenőrizd a Cloud Run logs-ot (app.py logging)
gcloud run services logs read ${SERVICE_NAME} --region=europe-west1
```

---

## 🎯 **Összefoglalva - Step 11 fájlok:**

```
step-11-website/
├── README.md                        ← TE VAGY ITT! 📖
├── providers.tf
├── variables.tf
├── locals.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
└── csv-browser/
    ├── .dockerignore
    ├── Dockerfile
    ├── app.py                       ← Flask web app
    ├── requirements.txt
    └── templates/
        └── index.html               ← Bootstrap UI
```

---

## ➡️ Következő lépés
👉 **Teljes pipeline tesztelése** (Drive → ... → CSV Export → **Web Browser**)

---

## 🎉 Gratulálunk!

Sikeresen létrehoztad a CSV Browser webes alkalmazást! Most már van egy szép UI-od a CSV fájlok böngészéséhez és letöltéséhez! 🚀🌐

**Teljes pipeline (VÉGSŐ VERZIÓ):**
1. ✅ File upload → Drive webhook
2. ✅ File Processor → GCS + BigQuery raw_data
3. ✅ Pub/Sub message → Dataform Trigger
4. ✅ Dataform Workflow → Aggregált táblák frissítése
5. ✅ Cloud Scheduler → CSV Export → GCS
6. ✅ **Webes böngésző → CSV letöltés** ← **TE VAGY ITT! 🎯**

**Use case-ek:**
- 📊 CSV böngészés és letöltés (nem kell gsutil vagy Console)
- 👥 Megosztás kollégákkal (public URL)
- 📈 Dashboard adatforrás kiválasztás
- 💾 Historikus adatok böngészése
- 📤 Külső rendszerek integráció (API endpoint-ként)

**NE FELEJTSD EL:**
- 🔨 Docker image build & push (3. lépés)
- 🔓 Unauthenticated access beállítása (9. lépés)
- 🌐 Élvezd a webes alkalmazást!