# Step 08: Dataform Aggregated Tables

## 🎯 Cél
BigQuery aggregált táblák létrehozása és Dataform SQL workflow-k előkészítése a nyers adatok transzformálására.

## ⚠️ **FONTOS: Előfeltételek**

**Step-02, Step-03, Step-04, Step-05 ÉS Step-06 resource-ainak létezniük KELL!**

Ha még nem futtattad le őket sorrendben:
```bash
cd ../step-02-service-account/ && terraform apply
cd ../step-03-storage/ && terraform apply
cd ../step-04-bigquery/ && terraform apply
cd ../step-05-iam/ && terraform apply
cd ../step-06-cloud-function-processor/ && terraform apply
```

**NE futtass `terraform destroy`-t az előző step-ekben!**

---

## 📦 Mit hoz létre ez a step?

### ÚJ resource-ok (step-08 specifikusak):
- ✅ 5x BigQuery Table (aggregált táblák üres sémákkal)
- ✅ 1x BigQuery Dataset IAM Binding (Data Editor - dataset szintű)
- ✅ 1x Project IAM Binding (Job User - project szintű)
- ✅ 2x Project IAM Binding (Dataform SA jogosultságok)
- ✅ 5x Generált SQLX fájl (template-ekből)
- ✅ 1x DATAFORM_SETUP.md instrukciós fájl

**Összesen: 9 ÚJ Terraform resource + 6 generált fájl**

### Már létező resource-ok (data sources):
- 📌 Service Account (step-02-ből)
- 📌 Storage Bucket - adatok tárolására (step-03-ból)
- 📌 BigQuery Dataset (step-04-ből)
- 📌 BigQuery Log Table (step-04-ből)
- 📌 BigQuery Raw Data Table (step-04-ből)
- 📌 BigQuery Processed Files Table (step-04-ből)
- 📌 Pub/Sub Topic (step-06-ból)
- 📌 Cloud Function Gen2 (step-06-ból)

---

## 📊 Aggregált táblák

A step **5 aggregált táblát** hoz létre a raw_data táblából:

### 1. **monthly_orders_by_ship_mode**
Havi értékesítés szállítási módok szerint
- `year_month` (STRING) - YYYY-MM formátum
- `ship_mode` (STRING) - Szállítási mód
- `total_sales` (FLOAT) - Összesített értékesítés
- `order_count` (INTEGER) - Rendelések száma

### 2. **monthly_orders_us_state**
USA államonkénti rendelések havi bontásban
- `year_month` (STRING) - YYYY-MM formátum
- `state` (STRING) - Állam neve
- `order_count` (INTEGER) - Rendelések száma

### 3. **monthly_favorite_product**
Top 10 termék havonta eladási darabszám szerint
- `year_month` (STRING) - YYYY-MM formátum
- `product_name` (STRING) - Termék neve
- `order_count` (INTEGER) - Eladott darabszám
- `total_sales` (FLOAT) - Összesített értékesítés
- `rank` (INTEGER) - Helyezés (1-10)

### 4. **monthly_customer_segment_analysis**
Ügyfél szegmens elemzés (átlagos kosárérték, egyedi vásárlók)
- `year_month` (STRING) - YYYY-MM formátum
- `segment` (STRING) - Ügyfél szegmens
- `order_count` (INTEGER) - Rendelések száma
- `total_sales` (FLOAT) - Összesített értékesítés
- `avg_order_value` (FLOAT) - Átlagos rendelési érték
- `unique_customers` (INTEGER) - Egyedi vásárlók száma

### 5. **monthly_category_revenue_trend**
Kategória bevételi trendek és piaci részesedés
- `year_month` (STRING) - YYYY-MM formátum
- `category` (STRING) - Főkategória
- `sub_category` (STRING) - Alkategória
- `total_sales` (FLOAT) - Összesített értékesítés
- `order_count` (INTEGER) - Rendelések száma
- `category_share` (FLOAT) - Piaci részesedés %-ban

---

## 🔧 Működés

### Terraform rész (automatikus):
1. 📊 Létrehozza az 5 aggregált tábla **üres sémáját** BigQuery-ben
2. 🔐 Beállítja a szükséges IAM jogosultságokat
3. 📝 Generálja a végleges `.sqlx` fájlokat a template-ekből
4. 📄 Elkészíti a `DATAFORM_SETUP.md` instrukciós fájlt

### Dataform rész (manuális):
1. 🗂️ Dataform repository és workspace létrehozása (GCP Console)
2. 📤 `.sqlx` fájlok feltöltése a workspace-be
3. ▶️ Dataform workflow futtatása
4. ✅ Aggregált táblák feltöltődnek adatokkal

---

## 📝 Lépések

### 1. Navigálj a könyvtárba
```bash
cd step-08-dataform/
```

### 2. Ellenőrizd a template fájlokat
```bash
ls -la dataform_templates/
```

Látnod kell 5 darab `.sqlx.tpl` fájlt.

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

⏱️ **Várható idő:** 30-60 másodperc

### 8. Ellenőrzés
```bash
terraform output
```

### 9. Generált fájlok ellenőrzése
```bash
ls -la generated_dataform/
cat DATAFORM_SETUP.md
```

Látnod kell:
- 5 darab `.sqlx` fájlt (végleges, paraméterezett verzió)
- 1 darab `DATAFORM_SETUP.md` instrukciós fájlt

---

## 📤 Outputs
- `service_account_email` - Service Account email (data source, step-02-ből)
- `bucket_name` - Adatok bucket neve (data source, step-03-ból)
- `dataset_id` - BigQuery dataset ID (data source, step-04-ből)
- `log_table_id` - Log tábla ID (data source, step-04-ből)
- `raw_data_table_id` - Raw data tábla ID (data source, step-04-ből)
- `processed_files_table_id` - Processed files tábla ID (data source, step-04-ből)
- `pubsub_topic_name` - Pub/Sub topic neve (data source, step-06-ból)
- `cloud_function_url` - Cloud Function URL (data source, step-06-ból)
- `aggregated_tables` - Létrehozott aggregált táblák listája (**ÚJ**)
- `generated_dataform_path` - Generált fájlok helye (**ÚJ**)

---

## 🔍 BigQuery táblák ellenőrzése GCP Console-ban

### Aggregált táblák (még üresek):
1. GCP Console → **BigQuery**
2. Navigálj a dataset-edhez: `{your-name}_demo_dataset`
3. Látod az 5 új táblát (csak a séma létezik, nincs adat):
   - `monthly_orders_by_ship_mode`
   - `monthly_orders_us_state`
   - `monthly_favorite_product`
   - `monthly_customer_segment_analysis`
   - `monthly_category_revenue_trend`

### IAM jogosultságok:
1. BigQuery → Dataset → **Sharing** → **Permissions**
2. Ellenőrizd:
   - Demo Service Account → `BigQuery Data Editor`

3. IAM & Admin → **IAM**
4. Ellenőrizd project-level jogosultságokat:
   - Demo Service Account → `BigQuery Job User`
   - Dataform Service Account → `Service Account Token Creator`
   - Dataform Service Account → `Service Account User`

---

## 📤 Dataform Setup (Manuális lépések)

A Terraform NEM tudja létrehozni a Dataform repository-t és workspace-t (még nincs támogatva a provider-ben).

### 1. Nyisd meg a generált instrukciós fájlt:
```bash
cat DATAFORM_SETUP.md
```

Vagy nyisd meg VS Code-ban / editor-ban.

### 2. Kövesd a lépéseket a `DATAFORM_SETUP.md`-ben:

**Röviden:**
1. Navigálj a Dataform Console-ra (link a fájlban)
2. Hozz létre egy Repository-t
3. Hozz létre egy Workspace-t
4. Töltsd fel a `generated_dataform/*.sqlx` fájlokat (drag & drop)
5. Futtasd a workflow-t → Az aggregált táblák feltöltődnek! 🎉

---

## 🧪 Aggregált táblák tesztelése

Miután a Dataform workflow lefutott, ellenőrizd az adatokat:

### 1. Havi értékesítés szállítási módok szerint
```sql
SELECT * 
FROM `{project_id}.{dataset_id}.monthly_orders_by_ship_mode`
ORDER BY year_month DESC, total_sales DESC
LIMIT 20;
```

### 2. USA államonkénti rendelések
```sql
SELECT * 
FROM `{project_id}.{dataset_id}.monthly_orders_us_state`
WHERE year_month = '2024-01'
ORDER BY order_count DESC
LIMIT 10;
```

### 3. Top 10 termékek
```sql
SELECT * 
FROM `{project_id}.{dataset_id}.monthly_favorite_product`
WHERE year_month = '2024-01'
ORDER BY rank;
```

### 4. Szegmens elemzés
```sql
SELECT 
  year_month,
  segment,
  order_count,
  total_sales,
  avg_order_value,
  unique_customers
FROM `{project_id}.{dataset_id}.monthly_customer_segment_analysis`
ORDER BY year_month DESC, total_sales DESC;
```

### 5. Kategória bevételi trendek
```sql
SELECT 
  year_month,
  category,
  sub_category,
  total_sales,
  category_share
FROM `{project_id}.{dataset_id}.monthly_category_revenue_trend`
WHERE year_month = '2024-01'
ORDER BY category_share DESC
LIMIT 20;
```

---

## 🗑️ Cleanup

**Csak a step-08 resource-ok törlése:**
```bash
terraform destroy
```

⚠️ **Figyelem:** Ez törli:
- 5 aggregált BigQuery táblát (a Dataform NEM törli - azt manuálisan kell a Console-ból)
- IAM binding-okat
- Generált fájlokat

Ez NEM törli:
- Service Account (step-02)
- Storage Bucket (step-03)
- BigQuery Dataset és raw_data tábla (step-04)
- IAM Bindings (step-05)
- Cloud Function és Pub/Sub (step-06)

**Dataform repository/workspace manuális törlése:**
1. GCP Console → Dataform
2. Válaszd ki a repository-t
3. Delete repository (törli a workspace-t is)

---

## 📚 Mit tanultunk?

- ✅ **Data source** használata (8 már létező resource)
- ✅ **BigQuery aggregált táblák** sémájának előkészítése
- ✅ **Template fájlok** generálása Terraform-mal (`templatefile()`)
- ✅ **local_file** resource használata
- ✅ **SQLX** fájlok írása (config + SQL)
- ✅ **WITH** clause és ablakfüggvények (ROW_NUMBER, QUALIFY)
- ✅ **PARSE_TIMESTAMP** használata (`%d/%m/%Y` formátum)
- ✅ **JOIN** műveletek aggregált adatokon
- ✅ **IAM jogosultságok** project és dataset szinten
- ✅ **Dataform SA jogosultságok** beállítása (Token Creator, SA User)
- ✅ Multi-step Terraform projektek

---

## 🔐 IAM & Permissions

### Demo Service Account (step-02-ből):
- ✅ Storage Object Admin (step-05)
- ✅ BigQuery Data Editor (step-05 + step-08)
- ✅ BigQuery Job User (step-08 - **PROJECT szintű**)
- ✅ Pub/Sub Publisher (step-06)

### Dataform Service Account (GCP managed):
- ✅ Service Account Token Creator (step-08 - **PROJECT szintű**)
- ✅ Service Account User (step-08 - **PROJECT szintű**)

---

## ⚠️ Fontos megjegyzések

- **Dataform repository/workspace:** Manuálisan kell létrehozni (Terraform még nem támogatja)
- **Template generálás:** Terraform automatikusan generálja a végleges `.sqlx` fájlokat
- **Manuális feltöltés:** A generált fájlokat drag & drop-pal kell feltölteni
- **Dátum formátum:** `%d/%m/%Y` parse formátum (pl. 01/12/2023 = December 1, 2023)
- **Idempotencia:** A Dataform táblák minden futtatáskor újra létrehozódnak
- **Üres táblák:** Terraform csak a sémát hozza létre, az adatokat a Dataform tölti fel
- **IAM szintek:** Figyelj oda, hogy melyik role dataset vs. project szintű!
- **Ez a step data source-okat használ** - nem hozza létre újra a már létező resource-okat!

---

## 🎯 **Összefoglalva - Step 08 fájlok:**

```
step-08-dataform/
├── README.md                        ← TE VAGY ITT! 📖
├── providers.tf
├── variables.tf
├── locals.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
├── dataform_templates/              ← Template fájlok (TF változókkal)
│   ├── monthly_orders_by_ship_mode.sqlx.tpl
│   ├── monthly_orders_us_state.sqlx.tpl
│   ├── monthly_favorite_product.sqlx.tpl
│   ├── monthly_customer_segment_analysis.sqlx.tpl
│   └── monthly_category_revenue_trend.sqlx.tpl
├── generated_dataform/              ← Generált végleges fájlok (ezt töltsd fel!)
│   ├── monthly_orders_by_ship_mode.sqlx
│   ├── monthly_orders_us_state.sqlx
│   ├── monthly_favorite_product.sqlx
│   ├── monthly_customer_segment_analysis.sqlx
│   └── monthly_category_revenue_trend.sqlx
└── DATAFORM_SETUP.md                ← Manuális setup instrukciók
```

---

## ➡️ Következő lépés
👉 **Dataform workflow futtatása** (GCP Console-ban, DATAFORM_SETUP.md szerint)
👉 És utána: Automatikusan, mikor a forrástábla frissül

---

## 🎉 Gratulálunk!

Sikeresen létrehoztad az aggregált táblák infrastruktúráját! A Dataform workflow futtatása után az adatok készen állnak dashboard-ok és riportok készítésére! 🚀📊