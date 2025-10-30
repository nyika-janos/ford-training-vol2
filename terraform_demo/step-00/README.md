# Step 00: Prerequisites & Setup

## 1. GCP CloudShell indítása

---

## 2. Upgrade terraform to the latest version

```bash
# Hozd létre a bin könyvtárat (ha még nincs)
mkdir -p ~/bin
cd ~/bin

# Töltsd le a legújabb Terraform verziót (pl. 1.13.4, ellenőrizheted a releases oldalon)
wget https://releases.hashicorp.com/terraform/1.13.4/terraform_1.13.4_linux_amd64.zip

# Csomagold ki
unzip terraform_1.13.4_linux_amd64.zip

# Tedd futtathatóvá
chmod +x terraform

# Add hozzá a PATH-hoz (ha még nem szerepel)
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Ellenőrizd
terraform -version

# Vissza a home-ba
cd ~
```

---

## 3. SA kulcsfájl letöltése

Console -> IAM -> Service Accounts -> `terraform@ford-training-430008.iam.gserviceaccount.com` -> Keys -> Add key -> Create new key -> JSON

---

## 4. SA kulcs felmásolása a CloudShellbe

Másold fel a letöltött kulcsfájlt a CloudShell `/home/<user_home>/` pathra `sa-key.json` néven.

---

## 5. GitHub repo klónozása

```bash
# Klónozd a repository-t
git clone https://github.com/nyika-janos/ford-training-vol2.git

# Lépj be a terraform demo könyvtárba
cd ford-training-vol2/terraform_demo
```

---

## 6. (Opcionális) GitHub Personal Access Token generálás

**Csak akkor szükséges, ha private repository-val dolgozol vagy authentication kell.**

GitHub -> Profile -> Settings -> Developer settings -> Personal access tokens -> Tokens (classic) -> Generate new token (classic) -> Password -> Note: "GCP usage", tick all -> Generate token -> Save

---

## 7. (Opcionális) Git inicializálása

**Csak akkor szükséges, ha új repository-t hozol létre.**

```bash
git init
```

---

## 8. (Opcionális) Add user.email & token (when asks for password)

**Csak akkor szükséges, ha még nincs beállítva a git config.**

---

## ➡️ Következő lépés

👉 `step-01-setup/`