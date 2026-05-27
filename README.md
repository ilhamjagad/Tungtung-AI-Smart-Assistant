# 🤖 Tungtung AI - Smart Assistant & Remote Control Laptop

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=FastAPI&logoColor=white" alt="FastAPI" />
  <img src="https://img.shields.io/badge/Ollama-000000?style=for-the-badge&logo=ollama&logoColor=white" alt="Ollama" />
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python" />
</div>

---

**Tungtung** adalah asisten AI pintar (Smart Assistant) berbasis lokal yang dikembangkan dengan teknologi **Flutter** untuk sisi aplikasi (frontend) dan **FastAPI** dengan model AI lokal **Ollama** sebagai pemroses kecerdasan buatan (backend). 

Asisten AI ini dirancang dengan kemampuan unik: tidak hanya menjawab pertanyaan, melainkan juga bertindak sebagai **Remote Control** untuk mengeksekusi berbagai perintah aplikasi di sistem operasi Windows Anda secara instan dan cerdas, serta mampu memahami file dokumen dan gambar.

---

## 🌟 Fitur Utama

### 🧠 1. Arsitektur AI Lokal "Dual Brain" (Dua Otak)
Tungtung beroperasi secara 100% offline dan lokal di laptop Anda menggunakan teknologi **Ollama**:
- **Qwen 2.5 (3B)**: Digunakan untuk pemrosesan teks, percakapan natural, logika cerdas, dan penulisan kode.
- **Moondream**: Digunakan sebagai otak penglihatan (vision model) untuk menganalisis gambar yang diunggah oleh pengguna secara visual.

### 📁 2. Smart Document Extractor & Analyzer
Dapat mengekstrak data teks dari dokumen yang diunggah langsung melalui aplikasi Flutter:
- **PDF (.pdf)** menggunakan `PdfReader`.
- **Word (.docx)** menggunakan `python-docx`.
- **File Teks & Code (.txt, .py, .dart, .json, .html, .css, .yaml, dll)**.
- Seluruh file dikonversi menjadi Base64 dari Flutter, kemudian diekstrak di backend FastAPI, dan dijadikan sebagai konteks tambahan bagi AI secara *real-time*.

### 💻 3. Laptop Remote Control Integration
Tungtung dapat langsung mengeksekusi aplikasi dan mengakses website di komputer/laptop Anda hanya melalui chat! 
Beberapa perintah kontrol yang didukung:
- **Websites**: Buka YouTube, WhatsApp Web, Claude AI, Gemini AI.
- **Browsers**: Buka Brave Browser, Microsoft Edge.
- **Productivity & Office**: Microsoft Word, Microsoft Excel.
- **Developer Tools**: Visual Studio Code (VS Code).
- **Creative & Communication**: Canva, Zoom, Netflix.

---

## 🛠️ Tech Stack

### Frontend (Tungtung)
- **Framework**: Flutter / Dart
- **Aplikasi**: Mobile / Desktop Client yang menawan, interaktif, dengan micro-animations modern.

### Backend (`/backend`)
- **Framework**: FastAPI (Python 3)
- **AI Engine**: Ollama (Qwen 2.5:3b & Moondream)
- **Libraries**:
  - `pydantic` untuk validasi data.
  - `pypdf` untuk ekstraksi dokumen PDF.
  - `python-docx` untuk ekstraksi file Word.
  - `webbrowser` & `subprocess` untuk eksekusi remote control di host machine.

---

## 🚀 Cara Menjalankan Project

### Prasyarat
1. Instal **Python 3.10+**.
2. Instal **Flutter SDK**.
3. Instal **Ollama** di komputer Anda.
   - Setelah menginstal Ollama, jalankan model-model berikut di terminal Anda:
     ```bash
     ollama pull qwen2.5:3b
     ollama pull moondream
     ```

### 1. Menjalankan Backend (FastAPI)
1. Buka folder `backend`:
   ```bash
   cd backend
   ```
2. Buat Virtual Environment baru dan aktifkan:
   ```bash
   python -m venv venv
   # Di Windows (PowerShell):
   .\venv\Scripts\Activate.ps1
   ```
3. Instal dependensi:
   ```bash
   pip install fastapi uvicorn ollama pypdf python-docx
   ```
4. Jalankan FastAPI server:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```
   *Server backend sekarang berjalan di `http://localhost:8000`.*

### 2. Menjalankan Frontend (Flutter)
1. Buka folder `Tungtung` di terminal terpisah:
   ```bash
   cd Tungtung
   ```
2. Ambil dependensi Flutter:
   ```bash
   flutter pub get
   ```
3. Jalankan aplikasi Flutter:
   ```bash
   flutter run
   ```

---

## 👤 Tentang Pengembang
Proyek ini dibuat dan dikembangkan oleh:
* **Muhammad Ilham Jagad** (Nodalixx)
* **Status**: Mahasiswa Teknik Informatika, UIN Syarif Hidayatullah Jakarta
* **Domisili**: Tangerang, Banten

---
<div align="center">
  <sub>Developed by Nodalixx.</sub>
</div>
