import base64
import io
import webbrowser
import subprocess
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Any
import ollama # type: ignore
from pypdf import PdfReader # type: ignore
import docx # type: ignore

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Struktur data baru untuk menerima lampiran dokumen
class FileData(BaseModel):
    name: str
    base64: str

class ChatRequest(BaseModel):
    pesan: str
    riwayat: List[Dict[str, Any]]
    files: List[FileData] = [] # Menampung list dokumen dari Flutter

# Fungsi cerdas untuk mengekstrak teks dari berbagai format file
def extract_text_from_base64(file_name: str, base64_str: str) -> str:
    try:
        # Ubah string base64 kembali menjadi bytes file asli
        file_bytes = base64.b64decode(base64_str)
        file_io = io.BytesIO(file_bytes)
        
        # Ekstraksi PDF
        if file_name.lower().endswith('.pdf'):
            reader = PdfReader(file_io)
            text = ""
            for page in reader.pages:
                text += page.extract_text() or ""
            return text
            
        # Ekstraksi Word (.docx)
        elif file_name.lower().endswith('.docx'):
            doc = docx.Document(file_io)
            return "\n".join([p.text for p in doc.paragraphs])
            
        # Ekstraksi File Teks / Kodingan (.txt, .py, .dart, .json, dll)
        elif file_name.lower().endswith(('.txt', '.py', '.dart', '.json', '.html', '.css', '.yaml')):
            return file_bytes.decode('utf-8', errors='ignore')
            
        else:
            return f"[Format file {file_name} tidak didukung untuk ekstraksi teks]"
            
    except Exception as e:
        return f"[Gagal membaca isi file {file_name}: {str(e)}]"

@app.post("/api/chat")
async def chat_endpoint(request: ChatRequest):
    system_prompt = {
        'role': 'system',
        'content': (
            'Kamu adalah AI Assistant pintar bernama "Tungtung".'
            'Kamu diciptakan/dibuat oleh Muhammad Ilham Jagad.'
            'Tugasmu adalah memberikan informasi dan menjawab pertanyaan pengguna dengan sebaik mungkin.'
            'Muhammad Ilham Jagad adalah seorang mahasiswa Teknik Informatika UIN Syarif Hidayatullah Jakarta.'
            'Muhammad Ilham Jagad berdomisili di Tangerang, Banten. dia lahir di tangerang, tanggal 19 Juli 2005.'
            'Muhammad Ilham Jagad menyukai Olahraga, Gaming, Musik, Travelling dan Teknologi'
            'Muhammad Ilham Jagad makanan kesukaannya adalah Nasi Goreng, Bakso, Mie Goreng, Mie Ayam, Ayam Goreng, Pempek. Makanan yang paling tidak ia suka adalah Tai.'
            'Club bola favorit Muhammad Ilham Jagad adalah FC Barcelona.'
            'Pemain bola favorit Muhammad Ilham Jagad adalah Lionel Messi'
            'Gunakan gaya bahasa Indonesia yang sopan, cerdas, profesional, namun tetap akrab dan suportif.'
        )
    }
    
    # ==========================================================
    # --- LOGIKA REMOTE CONTROL (EKSEKUSI PERINTAH LAPTOP) ---
    # ==========================================================
    pesan_user_lower = request.pesan.lower()
    aksi_sistem = ""

    if "buka youtube" in pesan_user_lower:
        webbrowser.open("https://www.youtube.com")
        aksi_sistem += " [Sistem Note: Berhasil membuka YouTube di laptop.]"

    if "buka whatsapp" in pesan_user_lower or "buka wa" in pesan_user_lower:
        webbrowser.open("https://web.whatsapp.com")
        aksi_sistem += " [Sistem Note: Berhasil membuka WhatsApp Web di laptop.]"

    if "buka claude" in pesan_user_lower:
        subprocess.Popen("explorer claude:", shell=True)
        aksi_sistem += " [Sistem Note: Berhasil membuka Claude AI di laptop.]"

    if "buka gemini" in pesan_user_lower:
        webbrowser.open("https://gemini.google.com/")
        aksi_sistem += " [Sistem Note: Berhasil membuka Gemini AI di laptop.]"

    if "buka browser" in pesan_user_lower:
        subprocess.Popen("start /MAX brave", shell=True)
        aksi_sistem += " [Sistem Note: Berhasil membuka browser Brave di laptop.]"
        
    if "buka word" in pesan_user_lower:
        subprocess.Popen("start /MAX winword", shell=True)
        aksi_sistem += " [Sistem Note: Berhasil membuka Microsoft Word di laptop.]"

    if "buka excel" in pesan_user_lower:
        subprocess.Popen("start /MAX excel", shell=True)
        aksi_sistem += " [Sistem Note: Berhasil membuka Microsoft Excel di laptop.]"

    if "buka vscode" in pesan_user_lower or "buka vs code" in pesan_user_lower or "buka visual studio code" in pesan_user_lower:
        subprocess.Popen("start /MAX code", shell=True)
        aksi_sistem += " [Sistem Note: Berhasil membuka VS Code di laptop.]"

    if "buka canva" in pesan_user_lower:
        subprocess.Popen(r'start /MAX "" "C:\Users\ilham\AppData\Local\Programs\Canva\Canva.exe"', shell=True)
        aksi_sistem += " [Sistem Note: Berhasil membuka Canva di laptop.]"

    if "buka zoom" in pesan_user_lower:
        subprocess.Popen(r'start /MAX "" "C:\Users\ilham\AppData\Roaming\Zoom\bin\Zoom.exe"', shell=True)
        aksi_sistem += " [Sistem Note: Berhasil membuka Zoom di laptop.]"
        
    if "buka netflix" in pesan_user_lower:
        subprocess.Popen('start /MAX msedge --app="https://www.netflix.com"', shell=True)
        aksi_sistem += " [Sistem Note: Berhasil membuka Netflix di laptop.]"
    
    # ==========================================================
    
    # --- PROSES EKSTRAKSI DOKUMEN ---
    dokumen_konteks = ""
    for file_attachment in request.files:
        teks_ekstraksi = extract_text_from_base64(file_attachment.name, file_attachment.base64)
        dokumen_konteks += f"\n\n--- DOKUMEN LAMPIRAN: {file_attachment.name} ---\n{teks_ekstraksi}\n"

    # --- PENGGABUNGAN KONTEKS UNTUK AI ---
    tambahan_konteks = ""
    if dokumen_konteks:
        tambahan_konteks += f"\n\n[Konteks Tambahan dari Dokumen Pengguna]:{dokumen_konteks}"
        
    if aksi_sistem:
        tambahan_konteks += f"\n\n{aksi_sistem}\n(Instruksi untuk AI: Beritahu pengguna bahwa kamu baru saja melaksanakan perintah tersebut di laptopnya dengan gaya bahasa asisten yang sigap)."

    # Selipkan konteks (dokumen/remote control) ke pesan terakhir pengguna
    if tambahan_konteks and len(request.riwayat) > 0:
        for msg in reversed(request.riwayat):
            if msg['role'] == 'user':
                msg['content'] += tambahan_konteks
                break
                
    messages_to_send = [system_prompt] + request.riwayat
    
    # --- LOGIKA "DUA OTAK" ---
    ada_gambar = False
    for pesan in request.riwayat:
        if 'images' in pesan and pesan['images']:
            ada_gambar = True
            break
            
    # Menggunakan model Qwen 2.5 (3B) untuk teks, atau Moondream untuk gambar
    model_ai = 'moondream' if ada_gambar else 'qwen2.5:3b'
    
    try:
        response = ollama.chat(model=model_ai, messages=messages_to_send)
        balasan_ai = response['message']['content']
        
        if not balasan_ai or balasan_ai.strip() == "":
            balasan_ai = "Maaf, saya tidak bisa memproses permintaan tersebut saat ini."
            
        return {"reply": balasan_ai}
        
    except Exception as e:
        return {"error": f"Gagal menggunakan model {model_ai}. Detail: {str(e)}"}