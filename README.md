# 🧠 MindMitra — AI Mental Health Platform
### Flutter App · FastAPI Backend · LangChain · Llama 3.1 · MongoDB Atlas
> Capstone Project

---

## What is MindMitra?

MindMitra is an AI-powered mental health support platform with a Flutter mobile/web frontend and a fully async Python REST API backend. It supports three user roles — **User**, **Professional**, and **Admin** — each with distinct features and data access.

**Core features:**
- 🤖 AI chatbot powered by **LangChain + Meta Llama 3.1-8B-Instruct** with persistent MongoDB-backed conversation memory
- 🚨 Two-stage **crisis detection** (keyword scan + LLM risk assessment) running concurrently with every chat response
- 📊 **Mood tracking** with Day/Week/Month graph views and streak counter
- 📓 **Smart journal** with automatic LLM emotion analysis on every entry
- 🧰 **Wellness toolkit** — breathing exercises, CBT activities, grounding techniques
- 👨‍⚕️ **Doctor portal** — link with professionals, share data with per-field consent controls
- 📋 **AI wellness report** — auto-generated from chat + mood + journal history
- 🔐 Role-based JWT authentication with Argon2 password hashing

---

## 📁 Repository Structure

```
MindMitra/
├── backend/          # FastAPI + LangChain + MongoDB backend
│   ├── main.py
│   ├── routes/
│   ├── services/
│   ├── utils/
│   ├── models/
│   ├── schemas/
│   └── README.md     # Full backend documentation
│
├── frontend/         # Flutter app (Android · iOS · Web)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   ├── services/
│   │   └── utils/
│   ├── web/
│   └── README.md     # Full frontend documentation
│
└── README.md         # This file
```

---

## 🛠 Tech Stack

### Backend
| | |
|---|---|
| Framework | FastAPI (fully async) + Uvicorn |
| AI | LangChain + Meta Llama 3.1-8B-Instruct (HuggingFace) |
| Database | MongoDB Atlas — Motor async driver |
| Auth | JWT (`python-jose`) + Argon2 (`passlib`) |
| Config | `pydantic-settings` |

### Frontend
| | |
|---|---|
| Framework | Flutter (Dart) |
| HTTP | Dio with JWT interceptor |
| Storage | flutter_secure_storage |
| Navigation | Named routes (MaterialApp) |
| Platforms | Android · iOS · Web |

---

## 🚀 Quick Start

### 1. Backend

```bash
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt

# Create .env (see backend/README.md for all variables)
cp .env.example .env   # then fill in your values

uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Swagger docs → `http://localhost:8000/docs`

### 2. Frontend

```bash
cd frontend
flutter pub get

# Update base URL in lib/services/core/api_service.dart:
# Real device  → http://YOUR_LOCAL_IP:8000
# Emulator     → http://10.0.2.2:8000

flutter run                  # mobile device
flutter run -d chrome        # web
```

---

## ⚙️ Environment Variables (Backend)

Create `backend/.env`:
```env
MONGODB_URL=mongodb+srv://<username>:<password>@cluster.mongodb.net/
DATABASE_NAME=mhc
SECRET_KEY=your_super_secret_key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_HOURS=84
HUGGINGFACEHUB_API_TOKEN=hf_your_token_here
HUGGING_FACE_MODEL=meta-llama/Llama-3.1-8B-Instruct
```

> ⚠️ Never commit `.env` to Git.

---

## 👤 User Roles & Login

| Role | Login | Home After Login |
|---|---|---|
| User | `/login` (any email) | Mood screen |
| Admin | `/login` (admin@admin.com) | Admin dashboard |
| Professional | `/proff_login` | Professional dashboard (if approved) |

Professionals must be approved by an admin before they can log in.

---

## 🗺 How It All Connects

```
Flutter App
    │
    │  HTTP + JWT (Dio)
    ▼
FastAPI Backend (routes/)
    │
    │  JWT guard → services/
    │
    ├── chat_service.py ──► LangChain + Llama 3.1 ──► MongoDB (chat_messages)
    │                   ──► crisis_detector.py (concurrent)
    │
    ├── journal_service.py ──► emotion_detector.py ──► Llama JSON analysis
    │
    ├── mood_service.py ──► MongoDB (moods)
    │
    └── profile_service.py ──► report_generator.py ──► Llama wellness report
```

---

## 📡 Key API Endpoints

| Feature | Method | Endpoint |
|---|---|---|
| Register | `POST` | `/auth/register` |
| Login | `POST` | `/auth/login` |
| Send chat message | `POST` | `/chat/{chat_id}` |
| Log mood | `POST` | `/mood/` |
| Mood stats (graph) | `GET` | `/mood/stats` |
| Create journal | `POST` | `/journal/` |
| Wellness toolkit | `GET` | `/toolkit/grouped` |
| AI wellness report | `GET` | `/profile/report/me` |
| Browse professionals | `GET` | `/professional/` |
| Admin verify professional | `PUT` | `/admin/professionals/{id}/verify` |

> See `backend/README.md` for the full API reference with request/response examples.

---

## 🚨 Crisis Detection

Runs **concurrently** with every chat response — zero latency impact.

```
Stage 1 → Instant keyword scan (15 crisis keywords)
Stage 2 → LLM risk check if no keyword found (none/mild/moderate/severe)
Crisis  → Alert saved to DB + helplines appended to bot response
        → Visible to linked professional and admin
```

Indian helplines included: iCall · AASRA · Vandrevala Foundation · 112

---

## 🗄 Database Collections

`users` · `chats` · `chat_messages` · `moods` · `journals` · `professional_links` · `crisis_alerts` · `sessions` · `professional_notes` · `reports`

---

## 📂 Full Documentation

- **Backend:** see [`backend/README.md`](./backend/README.md) — full API reference, AI architecture, DB schema, security
- **Frontend:** see [`frontend/README.md`](./frontend/README.md) — screens, routes, API service layer, configuration

---

## 👥 Team

Kanani Zainab · Patel Jyoti Bansilal · Parekh Vrunda Nirajbhai
>>>>>>> main
