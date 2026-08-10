# Windows Development Environment Kit

ชุด PowerShell สำหรับเตรียมและตรวจสอบ Development Environment บน Fresh Windows
โดยใช้ VS Code เป็นหลัก พร้อม Git/GitHub, Python, Node.js, WSL2 และ Docker Desktop

## ไฟล์ใน Repository

- `setup-dev.ps1` — ติดตั้งและตั้งค่า Development Environment
- `verify-dev.ps1` — ตรวจสอบว่า Environment พร้อมใช้งานหรือไม่
- `vscode-extensions.txt` — รายการ VS Code Extensions ที่ต้องการติดตั้ง
- `README.md` — คู่มือการติดตั้งและใช้งาน

---

# วิธีใช้งานบน Fresh Windows

## 1. เปิด PowerShell

เปิด PowerShell แบบปกติก่อน ไม่จำเป็นต้อง Run as Administrator
เว้นแต่ Windows หรือ installer ขอสิทธิ์ Administrator ระหว่างการติดตั้ง

ตรวจสอบว่า WinGet ใช้งานได้:

```powershell
winget --version
```

หากคำสั่งนี้แสดงเวอร์ชัน สามารถดำเนินการต่อได้

---

## 2. ดาวน์โหลดหรือ Clone Repository

ถ้ามี Git พร้อมใช้งานแล้ว สามารถ Clone Repository ได้:

```powershell
git clone https://github.com/qtaro66/git-environment-test.git
cd git-environment-test
```

ถ้ายังไม่มี Git สามารถดาวน์โหลด Repository เป็น ZIP จาก GitHub แล้ว Extract ก่อนก็ได้

---

# สำคัญ: Unblock PowerShell Script

Windows อาจทำเครื่องหมายไฟล์ `.ps1` ที่ดาวน์โหลดจาก Internet ว่าเป็นไฟล์จากภายนอก

หากรัน script แล้วพบข้อความประมาณ:

```text
cannot be loaded
The file ... is not digitally signed
```

ไม่จำเป็นต้องปิดระบบรักษาความปลอดภัยของ PowerShell

ให้ปลด Block เฉพาะ script ใน Repository นี้

## ปลด Block ทุกไฟล์ PowerShell ในโฟลเดอร์

เปิด PowerShell ที่โฟลเดอร์ Repository แล้วรัน:

```powershell
Get-ChildItem *.ps1 | Unblock-File
```

หรือปลดทีละไฟล์:

```powershell
Unblock-File .\setup-dev.ps1
Unblock-File .\verify-dev.ps1
```

จากนั้นสามารถรัน script ได้ตามปกติ

> ควรใช้ `Unblock-File` เฉพาะกับไฟล์ที่คุณเชื่อถือและทราบแหล่งที่มา

---

# 3. ตั้ง PowerShell Execution Policy

Development Environment นี้ใช้:

```text
CurrentUser = RemoteSigned
```

ตรวจสอบด้วย:

```powershell
Get-ExecutionPolicy -List
```

ถ้า `CurrentUser` ยังไม่ใช่ `RemoteSigned` ให้ตั้งด้วย:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

เมื่อ PowerShell ถามยืนยัน ให้เลือก:

```text
Y
```

การตั้งค่านี้เปลี่ยนเฉพาะ Windows user ปัจจุบัน ไม่ได้เปลี่ยน policy ของทั้งเครื่อง

---

# 4. รัน Setup Script

จากโฟลเดอร์ Repository:

```powershell
.\setup-dev.ps1
```

Script จะตรวจและติดตั้งเครื่องมือที่จำเป็น เช่น:

- Visual Studio Code
- Git for Windows
- Python
- Node.js LTS
- Docker Desktop
- VS Code Extensions
- Git configuration
- PowerShell configuration ที่จำเป็น

หากโปรแกรมมีอยู่แล้ว Script จะพยายามไม่ติดตั้งซ้ำโดยไม่จำเป็น

---

# 5. Restart Windows หากจำเป็น

Docker Desktop, WSL2 หรือ installer บางตัวอาจต้อง Restart Windows

หากมีข้อความขอ Restart ให้ Restart ก่อนทำขั้นตอนต่อไป

---

# 6. Sign in

การ Sign in จะไม่ถูกบันทึกไว้ใน PowerShell script

ให้ Sign in ด้วยตนเองเมื่อจำเป็น

### GitHub

Sign in ผ่าน VS Code / Git Credential Manager ตามปกติ

### Docker

Sign in Docker Desktop ตามบัญชี Docker ของคุณ

ห้ามเก็บ Password, Personal Access Token หรือ Docker Token ไว้ใน Repository นี้

---

# 7. เปิด Docker Desktop

ก่อนตรวจสอบ Environment ให้เปิด Docker Desktop และรอจน Docker Engine พร้อมใช้งาน

สามารถตรวจด้วย:

```powershell
docker info
```

และ:

```powershell
docker compose version
```

---

# 8. ตรวจสอบ Environment

รัน:

```powershell
.\verify-dev.ps1
```

Script จะตรวจ:

- WinGet
- VS Code
- Git
- Python
- pip
- Python virtual environment
- Node.js
- npm
- npx
- PowerShell Execution Policy
- WSL / WSL2
- Docker CLI
- Docker Engine
- Docker Compose
- Git configuration
- Git Credential Manager
- VS Code Extensions

เมื่อทุกอย่างเรียบร้อย ควรเห็น:

```text
Environment Status: READY
```

ถ้ามี Warning จะมีข้อความ:

```text
Warnings: ...
```

ถ้ามีปัญหาที่ต้องแก้ จะเห็น:

```text
[FAIL]
```

---

# 9. ทดสอบ GitHub บนเครื่องใหม่

Repository นี้สามารถใช้เป็น Git/GitHub test repository ได้ด้วย

ตรวจ Remote:

```powershell
git remote -v
```

ตรวจสถานะ:

```powershell
git status
```

ลองแก้ README เล็กน้อย แล้วทดสอบ:

```powershell
git add README.md
git commit -m "Test Git on new machine"
git push
```

หาก Push สำเร็จ แสดงว่าเส้นทางนี้ทำงานครบ:

```text
VS Code
   ↓
Git
   ↓
Git Credential Manager
   ↓
GitHub
```

---

# Python Project Guideline

แต่ละ Python project ควรมี Virtual Environment ของตัวเอง

สร้าง:

```powershell
python -m venv .venv
```

Activate:

```powershell
.\.venv\Scripts\Activate.ps1
```

และควรมีใน `.gitignore`:

```gitignore
.venv/
```

ไม่ควร Push `.venv` ขึ้น GitHub

---

# Node.js Project Guideline

ESLint และ Prettier VS Code Extensions สามารถติดตั้งระดับ VS Code ได้

แต่ package ของแต่ละ project ควรติดตั้งใน project ผ่าน `package.json`
แทนการติดตั้ง global เช่น:

```text
npm install -g eslint
npm install -g prettier
```

เพื่อให้แต่ละ project สามารถกำหนด version ของ dependency ได้เอง

---

# Reference Environment

Environment ที่ใช้ตรวจสอบชุด script นี้สำเร็จ:

```text
VS Code            1.132.0 x64
Git                2.55.0.windows.3
Python             3.14.7
pip                26.2.1
Node.js            24.19.0
npm / npx          11.17.0
Docker Engine      29.7.2
Docker Compose     v5.3.1
WSL                2.7.11
WSL Default        Version 2
PowerShell Policy  CurrentUser = RemoteSigned
```

เลขเวอร์ชันเหล่านี้เป็น Reference เท่านั้น
ไม่จำเป็นต้องบังคับให้เครื่องใหม่ใช้เวอร์ชันเดียวกันทุกตัว

---

# Quick Start

สำหรับเครื่องใหม่ที่ Git พร้อมใช้งานแล้ว:

```powershell
git clone https://github.com/qtaro66/git-environment-test.git
cd git-environment-test

Get-ChildItem *.ps1 | Unblock-File

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

.\setup-dev.ps1
```

หลัง Setup และ Restart (ถ้าจำเป็น):

```powershell
cd $HOME\git-environment-test
.\verify-dev.ps1
```

เป้าหมายสุดท้าย:

```text
Environment Status: READY
```
