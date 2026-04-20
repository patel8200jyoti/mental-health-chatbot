# 🧠 The MindMitra — AI Mental Health Chatbot
### Backend API · Capstone Project

> A fully async Python REST API powering an AI-driven mental health support application.
> Built with **FastAPI**, **LangChain**, **Meta Llama 3.1-8B-Instruct** (HuggingFace), and **MongoDB Atlas**.

---

## 📑 Table of Contents

1. [Project Overview](#-project-overview)
2. [Tech Stack](#-tech-stack)
3. [Project Structure](#-project-structure)
4. [How Files Are Connected](#-how-files-are-connected)
5. [Getting Started](#-getting-started)
6. [Environment Variables](#-environment-variables)
7. [API Reference](#-api-reference)
   - [Authentication](#authentication)
   - [Chat — LangChain + Llama 3.1](#chat--langchain--llama-31)
   - [Mood Tracking](#mood-tracking)
   - [Journal](#journal)
   - [Toolkit](#toolkit)
   - [Profile & Report](#profile--report)
   - [Professional](#professional)
   - [User–Doctor Portal](#userdoctor-portal-my-doctor)
   - [Admin](#admin)
8. [AI Architecture](#-ai-architecture)
9. [Database Schema](#-database-schema)
10. [Security](#-security)
11. [Crisis Detection System](#-crisis-detection-system)
12. [Team](#-team)

---

## 🔍 Project Overview

The MindMitra backend is the server-side engine of an AI-powered mental health chatbot app. It serves a Flutter mobile frontend via REST API and supports three user roles — **User**, **Professional**, and **Admin** — each with distinct permissions and data access.

**Core capabilities:**
- 🤖 AI chatbot powered by **LangChain + Meta Llama 3.1-8B-Instruct** with persistent MongoDB-backed conversation memory
- 🚨 **Two-stage crisis detection** (keyword scan + LLM risk assessment) running concurrently with every chat response
- 📓 **Automatic LLM emotion analysis** on every journal entry — returns mood, sentiment score, and a supportive reflection
- 🔗 Doctor–patient linking with **per-professional, per-data-type consent controls**
- 🔐 Role-based JWT authentication with **Argon2** password hashing and bcrypt fallback

---

## 🛠 Tech Stack

| Category | Technology |
|---|---|
| Framework | FastAPI (fully async) |
| Server | Uvicorn (ASGI) |
| LLM | Meta Llama 3.1-8B-Instruct via HuggingFace Endpoints |
| AI Orchestration | LangChain (`langchain-huggingface`) |
| Database | MongoDB Atlas — Motor async driver |
| Authentication | JWT via `python-jose` |
| Password Hashing | Argon2 + bcrypt fallback via `passlib` |
| Config Management | `pydantic-settings` (BaseSettings) |
| Environment | `python-dotenv` |

---

## 📁 Project Structure

```
backend/
│
├── main.py                  # FastAPI app — registers all routers, CORS middleware, startup/shutdown events
├── database.py              # MongoDB connection singleton using Motor (AsyncIOMotorClient)
├── config.py                # All environment variables loaded via pydantic_settings.BaseSettings
├── .env                     # Secret keys, DB URL, HuggingFace token — never commit this
│
├── routes/                  # API layer — defines endpoints, validates JWT, calls services
│   ├── auth.py              # POST /auth/register  POST /auth/login  get_current_user() dependency
│   ├── chat.py              # CRUD for chat sessions + POST /chat/{id} → triggers LangChain pipeline
│   ├── mood.py              # POST /mood/  GET /mood/week|all|stats|streak
│   ├── journal.py           # CRUD /journal/ — save/update auto-triggers Llama emotion analysis
│   ├── profile.py           # GET /profile/me  GET|POST /profile/report/me
│   ├── toolkit.py           # GET /toolkit/  /toolkit/grouped  /toolkit/{id}
│   ├── professional.py      # Professional dashboard, patient management, crisis alerts, notes
│   ├── user_proff.py        # User-facing doctor portal — /my-doctor/... links, sessions, messages
│   └── admin.py             # Admin stats, user/professional management, verify/reject
│
├── services/                # Business logic layer — routes call these, these talk to DB and utils
│   ├── auth_service.py      # get_user()  create_user() — MongoDB users collection
│   ├── chat_service.py      # chat_with_bot() — full LangChain + Llama pipeline + crisis handling
│   ├── mood_service.py      # create_mood()  get_week_moods()  get_mood_stats()  calculate_streak()
│   ├── journal_service.py   # create_journal()  fetch_journal()  update_journal()  delete_journal()
│   ├── crisis_service.py    # save_crisis_alert()  build_crisis_response() — appends helplines
│   ├── profile_service.py   # get_user_profile()  generate_report() — uses report_generator util
│   ├── professional_service.py  # Professional DB operations
│   ├── admin_service.py     # Admin stats queries across all collections
│   └── toolkit_services.py  # Reads and filters data from data/toolkit_data.py
│
├── utils/                   # Reusable AI + security utilities — services call these
│   ├── memory_history.py    # MemoryHistory class — loads/saves MongoDB chat docs as LangChain HumanMessage/AIMessage
│   ├── emotion_detector.py  # analyse_journal() + analyse_chats() — LangChain prompt chains → Llama JSON output
│   ├── crisis_detector.py   # detect_crisis() — keyword scan (instant) then LLM risk assessment
│   ├── report_generator.py  # summarize_chats() + generate_final_report() — Llama wellness report
│   ├── security.py          # hash_password()  verify_password()  create_access_token()  verify_token()
│   └── sec_p.py             # Additional security helpers
│
├── models/                  # Pydantic models — validate and type-check incoming request bodies
│   ├── user_chcek.py        # UserCreate  UserLogin  Token
│   ├── chat.py              # ChatMessage  Chats
│   ├── mood_check.py        # MoodCreate  MoodResponse
│   ├── journal.py           # JournalCreate
│   └── professional.py      # ProfessionalNote  SessionRequest  PermissionsUpdate
│
├── schemas/                 # MongoDB serializers — convert raw DB documents ↔ clean response dicts
│   ├── user.py              # user_entity() for insert · user_schema() for response
│   ├── chat.py              # chat_entity() · chat_schema()
│   ├── mood.py              # mood_entity() · mood_schema()
│   ├── journal.py           # journal_entity() · journal_schema()
│   └── admin.py             # _serialize_user() · _serialize_professional()
│
└── data/
    └── toolkit_data.py      # Static list of all toolkit content — no DB writes needed
```

---

## 🔗 How Files Are Connected

### 1. App Startup — `main.py` → `database.py` → `config.py`

```
.env file
  └──► config.py
         └── pydantic BaseSettings reads MONGODB_URL, SECRET_KEY,
             HUGGINGFACEHUB_API_TOKEN, DATABASE_NAME, etc.
               └──► database.py
                      └── connect_to_mongo() creates AsyncIOMotorClient
                          stores it in Database singleton (db.client)
                            └──► get_database() called by every service
                                 returns db.client[settings.DATABASE_NAME]
```

`main.py` registers all 9 routers, adds CORS middleware, and hooks `connect_to_mongo()` on startup and `close_mongo()` on shutdown.

---

### 2. Every Request — `routes/` → `services/` → `utils/` → `database.py`

```
Flutter App  ──HTTP Request + JWT──►  main.py
                                          │
                                     routes/*.py
                                          │  Pydantic model validates request body
                                          │  Depends(get_current_user) checks JWT
                                          │
                                     services/*.py
                                          │  calls get_database() → MongoDB
                                          │  calls utils/* for AI / security
                                          │
                                     schemas/*.py
                                          │  converts MongoDB doc → clean dict
                                          │
                                     JSON Response ──────────────► Flutter App
```

---

### 3. Chat Request — Full LangChain Pipeline

`POST /chat/{chat_id}` with `{"message": "I feel really anxious today"}`

```
routes/chat.py
  │  Depends(get_current_user) validates JWT → extracts user_id
  │
  ▼
services/chat_service.py  →  chat_with_bot(user_id, chat_id, user_input)
  │
  ├──► utils/memory_history.py  →  MemoryHistory(chat_id).load_message()
  │         calls get_database()
  │         queries chat_messages collection (last 50 docs, sorted by created_at)
  │         converts each doc → HumanMessage or AIMessage (LangChain objects)
  │         returns history list
  │
  │    Assembles message list:
  │    [SystemMessage(persona_template)] + [history...] + [HumanMessage(user_input)]
  │
  ├──► asyncio.gather() — runs BOTH concurrently (no added latency):
  │         │
  │         ├── utils/crisis_detector.py  →  detect_crisis(user_input)
  │         │         keyword_check() — instant scan of 15 crisis keywords
  │         │         if no match → llm_crisis_check() via LangChain chain → Llama
  │         │         returns {is_crisis: bool, method: "keyword"|"llm"|"none"}
  │         │
  │         └── model.ainvoke(message_list)
  │                   ChatHuggingFace wrapping HuggingFaceEndpoint
  │                   uses settings.HUGGINGFACEHUB_API_TOKEN from config.py
  │                   returns Llama 3.1 response text
  │
  ├──► utils/memory_history.py  →  save_message() for user message:
  │         calls utils/emotion_detector.py  →  analyse_chats(user_message)
  │               LangChain ChatPromptTemplate | model chain → Llama JSON
  │               returns emotion string (sad, anxious, happy, etc.)
  │         inserts into chat_messages with emotion tag
  │
  ├──► utils/memory_history.py  →  save_message() for bot response
  │         inserts into chat_messages with crisis_detected flag
  │
  └──► if is_crisis == True:
            services/crisis_service.py  →  save_crisis_alert()
                  inserts into crisis_alerts collection
                  {user_id, chat_id, message, detection_method, resolved: false}
            services/crisis_service.py  →  build_crisis_response()
                  appends Indian helplines to bot response text

  Returns: {response: "...", crisis_detected: true|false}
```

---

### 4. Journal Create — AI Analysis Auto-Triggered

`POST /journal/` with `{"content": "Today was really hard for me..."}`

```
routes/journal.py
  │  Depends(get_current_user)
  ▼
services/journal_service.py  →  create_journal()
  │
  ├──► utils/emotion_detector.py  →  analyse_journal(content)
  │         ChatPromptTemplate | ChatHuggingFace chain
  │         Llama 3.1 returns strict JSON:
  │         { "mood": "sad", "sentiment_score": 0.28, "reflection": "..." }
  │         try/except returns safe defaults if JSON parse fails
  │
  ├──► schemas/journal.py  →  journal_entity()
  │         builds MongoDB document with content + AI analysis fields
  │
  └──► get_database()  →  db.journals.insert_one()
            saved to MongoDB journals collection

  Same flow for PUT /journal/{id} — re-runs analyse_journal() on update
```

---

### 5. JWT Auth — Every Protected Route

```
Any protected route (e.g. GET /mood/week)
  │
  ▼
Depends(get_current_user)  in routes/auth.py
  │  reads Authorization: Bearer <token> from request header
  │
  ▼
utils/security.py  →  verify_token(token)
  │  python-jose decodes JWT using settings.SECRET_KEY from config.py
  │  returns user_email from token "sub" field
  │
  ▼
get_database()  →  db.users.find_one({"user_email": email})
  │
  ▼
schemas/user.py  →  user_schema(user)
  └──► returns clean user dict used throughout the rest of the request
```

---

### 6. Admin — Extra Role Guard

```
Any admin route (e.g. PUT /admin/professionals/{id}/verify)
  │
  ▼
Depends(require_admin)  in routes/admin.py
  │  calls get_current_user() → JWT check + DB fetch
  │  checks user["role"] == "admin"
  │  raises 403 Forbidden if not admin
  │
  ▼
services/admin_service.py
  └──► queries users, journals, chats, moods, crisis_alerts via get_database()
```

---

### 7. Config — Used Everywhere

`config.py` (`Settings` class via `pydantic_settings.BaseSettings`) is the single source of truth:

| File | Settings Used |
|---|---|
| `database.py` | `MONGODB_URL`, `DATABASE_NAME` |
| `utils/security.py` | `SECRET_KEY`, `ALGORITHM`, `ACCESS_TOKEN_EXPIRE_HOURS` |
| `utils/emotion_detector.py` | `HUGGINGFACEHUB_API_TOKEN` |
| `utils/crisis_detector.py` | `HUGGINGFACEHUB_API_TOKEN` |
| `services/chat_service.py` | HuggingFace token (loaded at module level) |
| `main.py` | `CORS_ORIGINS` |

---

### Quick Layer Summary

| Layer | Files | Role |
|---|---|---|
| **Entry point** | `main.py` | Boots app, registers all routers, connects DB |
| **Config** | `config.py` + `.env` | All secrets and settings in one place |
| **DB connection** | `database.py` | Singleton Motor client, `get_database()` |
| **Routes** | `routes/*.py` | HTTP endpoints, JWT guard, calls services |
| **Services** | `services/*.py` | Business logic, DB queries, calls utils |
| **AI utils** | `utils/memory_history.py`, `emotion_detector.py`, `crisis_detector.py` | LangChain + Llama pipelines |
| **Security** | `utils/security.py` | Password hash, JWT create/verify |
| **Models** | `models/*.py` | Pydantic — validates incoming request bodies |
| **Schemas** | `schemas/*.py` | Converts MongoDB docs ↔ clean response dicts |
| **Static data** | `data/toolkit_data.py` | Toolkit content, no DB needed |

---

## 🚀 Getting Started

### Prerequisites

- Python 3.11+
- MongoDB Atlas account (or local MongoDB)
- HuggingFace account with API token
- Access approved for `meta-llama/Llama-3.1-8B-Instruct` on HuggingFace

### Installation

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd backend

# 2. Create a virtual environment
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt
```

### Run the Server

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

| URL | Description |
|---|---|
| `http://localhost:8000` | API base URL |
| `http://localhost:8000/docs` | Swagger UI — interactive API explorer |
| `http://localhost:8000/redoc` | ReDoc API documentation |

---

## ⚙️ Environment Variables

Create a `.env` file in the root of the backend folder:

```env
# MongoDB
MONGODB_URL=mongodb+srv://<username>:<password>@cluster.mongodb.net/
DATABASE_NAME=mhc

# JWT
SECRET_KEY=your_super_secret_key_here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_HOURS=84

# HuggingFace — Llama 3.1
HUGGINGFACEHUB_API_TOKEN=hf_your_token_here
HUGGING_FACE_MODEL=meta-llama/Llama-3.1-8B-Instruct
```

> ⚠️ **Never commit `.env` to Git.** Add it to `.gitignore`.

All variables are loaded automatically by `config.py` using `pydantic_settings.BaseSettings`.

---

## 📡 API Reference

All protected routes require:
```
Authorization: Bearer <access_token>
```

🔒 = JWT required · ❌ = No auth needed

---

### Authentication

**Prefix:** `/auth`

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/auth/register` | ❌ | Register a new user |
| `POST` | `/auth/login` | ❌ | Login — returns JWT access token |

#### POST `/auth/register`
```json
{
  "user_email": "user@example.com",
  "password": "securepassword",
  "user_name": "Zainab",
  "user_dob": "2002-05-14",
  "user_gender": "Female"
}
```

#### POST `/auth/login`
FastAPI OAuth2 form encoding — Flutter sends email in the `username` field.
```
Content-Type: application/x-www-form-urlencoded
username=user@example.com&password=securepassword
```
**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer"
}
```

---

### Chat — LangChain + Llama 3.1

**Prefix:** `/chat` · 🔒

Loads conversation history from MongoDB, assembles a LangChain message list, and runs crisis detection + LLM response concurrently via `asyncio.gather()`.

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/chat/` | Create a new chat session |
| `GET` | `/chat/list` | List all chats (title auto-set from first message) |
| `GET` | `/chat/{chat_id}` | Get all messages in a chat |
| `POST` | `/chat/{chat_id}` | Send message — get Llama 3.1 response |
| `DELETE` | `/chat/{chat_id}/clear` | Clear all messages in a chat |
| `DELETE` | `/chat/{chat_id}` | Delete chat session + all messages |

#### POST `/chat/{chat_id}` — Send Message
```json
{ "message": "I've been feeling really anxious lately" }
```

**Normal response:**
```json
{
  "response": "It sounds like you're carrying a lot right now...",
  "crisis_detected": false
}
```

**Crisis response:**
```json
{
  "response": "I'm really concerned about your safety right now...\n\n💙 Emergency Support Resources:\n• iCall (India): 9152987821\n• AASRA: 9820466627\n• Vandrevala Foundation: 1860-2662-345",
  "crisis_detected": true
}
```

#### GET `/chat/list`
```json
[
  {
    "chat_id": "550e8400-e29b-41d4-a716-446655440000",
    "chat_title": "I've been feeling really anx…",
    "created_at": "2025-06-10T14:30:00"
  }
]
```

---

### Mood Tracking

**Prefix:** `/mood` · 🔒

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/mood/` | Log today's mood |
| `GET` | `/mood/week` | Last 7 days of mood data |
| `GET` | `/mood/all` | Full mood history |
| `GET` | `/mood/stats` | Aggregated daily / weekly / monthly averages |
| `GET` | `/mood/streak` | Current consecutive-day logging streak |

#### POST `/mood/`
```json
{
  "user_mood": "happy",
  "mood_score": 5,
  "mood_date": "2025-06-10"
}
```

**Mood score scale:**

| Mood | Score |
|---|---|
| `sad` | 2 |
| `okay` | 3 |
| `calm` | 4 |
| `happy` | 5 |
| `great` | 6 |

#### GET `/mood/stats`
```json
{
  "daily":   [{ "date": "2025-06-10", "avg_score": 4.5 }],
  "weekly":  [{ "year": 2025, "week": 23, "avg_score": 4.2 }],
  "monthly": [{ "year": 2025, "month": 6,  "avg_score": 4.0 }]
}
```

---

### Journal

**Prefix:** `/journal` · 🔒

Every entry is automatically analysed by **Llama 3.1 via LangChain** — returns mood classification, sentiment score (0–1), and a supportive reflection. Analysis re-runs on every update.

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/journal/` | Create entry — auto AI analysis |
| `GET` | `/journal/` | List all entries (newest first) |
| `PUT` | `/journal/{id}` | Update entry — re-runs AI analysis |
| `DELETE` | `/journal/{id}` | Delete entry |

#### POST `/journal/`
```json
{ "content": "Today was overwhelming. I couldn't focus at all." }
```

**Response:**
```json
{
  "id": "64abc123def456...",
  "content": "Today was overwhelming...",
  "mood": "sad",
  "sentiment_score": 0.28,
  "reflection": "It sounds like you faced a really tough day. Your feelings are completely valid, and it's okay to take things one step at a time.",
  "created_at": "2025-06-10T10:00:00"
}
```

---

### Toolkit

**Prefix:** `/toolkit` · 🔒

Static mental health self-care content. All data is defined in `data/toolkit_data.py` — no database writes needed.

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/toolkit/` | All toolkit items |
| `GET` | `/toolkit/grouped` | Items grouped by category |
| `GET` | `/toolkit/{id}` | Single item by ID |

**Categories:** Breathing Exercises · CBT Activities · Grounding Techniques · Daily Wellness Tips · Self-Assessment

---

### Profile & Report

**Prefix:** `/profile` · 🔒

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/profile/me` | Current user's profile |
| `GET` | `/profile/report/me` | Get AI-generated wellness report |
| `POST` | `/profile/report/me` | Regenerate wellness report |

The wellness report is generated by `utils/report_generator.py` — it summarizes the user's chat history, journal entries, and mood data using Llama 3.1 and stores the result in the `reports` collection.

---

### Professional

**Prefix:** `/professional`

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/professional/register` | ❌ | Register as professional (pending admin approval) |
| `GET` | `/professional/me` | 🔒 | Own professional profile |
| `GET` | `/professional/` | ❌ | Browse all approved professionals |
| `POST` | `/professional/request` | 🔒 | Send link request to a professional |
| `GET` | `/professional/dashboard/stats` | 🔒 | Dashboard summary stats |
| `GET` | `/professional/patients` | 🔒 | All linked patients |
| `GET` | `/professional/patients/pending` | 🔒 | Pending link requests |
| `POST` | `/professional/patients/{user_id}/respond` | 🔒 | Accept or reject a link request |
| `DELETE` | `/professional/patients/{user_id}` | 🔒 | Unlink a patient |
| `GET` | `/professional/patients/{user_id}/profile` | 🔒 | Patient's full profile |
| `GET` | `/professional/patients/{user_id}/moods` | 🔒 | Patient mood history (if permitted) |
| `GET` | `/professional/patients/{user_id}/journals` | 🔒 | Patient journals (if permitted) |
| `GET` | `/professional/crisis` | 🔒 | Crisis alerts for linked patients |
| `POST` | `/professional/crisis/{alert_id}/resolve` | 🔒 | Mark crisis alert as resolved |
| `GET` | `/professional/patients/{user_id}/notes` | 🔒 | Get notes on a patient |
| `POST` | `/professional/patients/{user_id}/notes` | 🔒 | Add a clinical note |
| `DELETE` | `/professional/patients/{user_id}/notes/{note_id}` | 🔒 | Delete a note |

#### POST `/professional/register`
```json
{
  "user_email": "doctor@example.com",
  "password": "secure123",
  "full_name": "Dr. Priya Shah",
  "user_dob": "1985-03-20",
  "user_gender": "Female",
  "medical_registration_number": "MH-12345",
  "state_medical_council": "Maharashtra Medical Council",
  "year_of_registration": "2010",
  "educational_qualifications": "MD Psychiatry"
}
```

> ⚠️ Professionals cannot log in until an admin approves their account via `PUT /admin/professionals/{id}/verify`.

#### POST `/professional/patients/{user_id}/respond`
```json
{ "accept": true }
```

---

### User–Doctor Portal (`/my-doctor`)

**Prefix:** `/my-doctor` · 🔒

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/my-doctor/links` | All my link records (any status) |
| `GET` | `/my-doctor/link/{prof_id}` | Link info + current permissions |
| `PUT` | `/my-doctor/link/{prof_id}/permissions` | Update data sharing permissions |
| `DELETE` | `/my-doctor/link/{prof_id}` | Unlink a professional |
| `DELETE` | `/my-doctor/request/{prof_id}` | Cancel a pending request |
| `GET` | `/my-doctor/{prof_id}/profile` | Professional's public profile |
| `POST` | `/my-doctor/{prof_id}/sessions` | Request a session |
| `GET` | `/my-doctor/{prof_id}/sessions` | List sessions with a professional |
| `POST` | `/my-doctor/{prof_id}/messages` | Send a portal message |
| `GET` | `/my-doctor/{prof_id}/messages` | Get all portal messages |

#### PUT `/my-doctor/link/{prof_id}/permissions`
```json
{
  "allow_mood": true,
  "allow_journal": false
}
```

#### POST `/my-doctor/{prof_id}/sessions`
```json
{
  "session_date": "2025-06-15T10:00:00",
  "session_type": "Consultation",
  "note": "Would like to discuss anxiety management strategies"
}
```

---

### Admin

**Prefix:** `/admin` · 🔒 `role: admin` required

Protected by `require_admin` dependency — returns `403 Forbidden` if JWT role is not `admin`.

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/admin/stats` | Total users, professionals, pending approvals, journals |
| `GET` | `/admin/stats/dashboard` | Active chats, total messages, streak users |
| `GET` | `/admin/stats/moods` | Mood trends — query param `?range=W\|M\|Y` |
| `GET` | `/admin/users` | All registered users |
| `GET` | `/admin/professionals` | All professionals (any status) |
| `PUT` | `/admin/professionals/{id}/verify` | Approve a professional account |
| `PUT` | `/admin/professionals/{id}/reject` | Reject a professional application |
| `GET` | `/admin/crisis` | All unresolved crisis alerts |

---

## 🤖 AI Architecture

### LangChain + Llama 3.1 Chat Pipeline

```
User Message
     │
     ▼
MemoryHistory.load_message()
     │  queries chat_messages collection (last 50, sorted by created_at asc)
     │  converts each doc → HumanMessage (role=user) or AIMessage (role=assistant)
     ▼
Assemble LangChain message list:
[ SystemMessage(persona_template) ] + [ ...history ] + [ HumanMessage(user_input) ]
     │
     ▼
asyncio.gather() — runs CONCURRENTLY (zero latency cost):
     ├── detect_crisis(user_input)      → {is_crisis, method}
     └── model.ainvoke(message_list)    → bot response text
     │
     ▼
Save messages to MongoDB (chat_messages collection):
     ├── user message  →  with emotion tag from analyse_chats()
     └── bot response  →  with crisis_detected flag
     │
     ▼
Crisis detected?
  YES ──► save_crisis_alert()       → insert into crisis_alerts collection
      ──► build_crisis_response()   → append helplines to response
  NO  ──► return response as-is
```

### Emotion Analysis — `utils/emotion_detector.py`

Two LangChain `ChatPromptTemplate | ChatHuggingFace` chains:

| Function | Called By | Returns |
|---|---|---|
| `analyse_journal(content)` | `journal_service.create_journal()` and `update_journal()` | `{mood, sentiment_score, reflection}` |
| `analyse_chats(message)` | `memory_history.save_message()` for every user message | emotion string stored in `chat_messages.emotion` |

Both chains instruct Llama 3.1 to return **strict JSON only**. `try/except` around `json.loads()` returns safe defaults on failure — prevents API errors from propagating.

### Chatbot System Prompt Persona

The `SystemMessage` injected into every chat instructs Llama 3.1 to be:

- A **compassionate, non-judgmental** mental health support assistant
- Use **reflective listening** — *"It sounds like you're feeling..."*
- Offer **CBT-based coping strategies** and grounding techniques when appropriate
- **Never** diagnose conditions or provide medical/psychiatric advice
- **Prioritize safety** above all else if crisis signals are detected
- Avoid toxic positivity and clinical/robotic language
- Internally assess emotional intensity and risk level — without stating it explicitly

---

## 🗄 Database Schema

All collections stored in **MongoDB Atlas**. User and chat IDs are `UUID` strings. Journal and message IDs use MongoDB `ObjectId`.

### `users`
```json
{
  "user_id": "uuid-string",
  "user_email": "string",
  "user_name": "string",
  "password": "argon2-hash",
  "role": "user | professional | admin",
  "user_dob": "date-string",
  "user_gender": "string",
  "is_approved": false,
  "disabled": false,
  "created_at": "datetime"
}
```

### `chats`
```json
{
  "chat_id": "uuid-string",
  "user_id": "uuid-string",
  "chat_title": "Auto-set from first 30 chars of first user message",
  "created_at": "datetime"
}
```

### `chat_messages`
```json
{
  "chat_id": "uuid-string",
  "user_id": "uuid-string",
  "message": "string",
  "role": "user | assistant",
  "emotion": "sad | anxious | happy | calm | ...",
  "crisis_detected": false,
  "created_at": "datetime"
}
```

### `moods`
```json
{
  "user_id": "uuid-string",
  "user_mood": "sad | okay | calm | happy | great",
  "mood_score": 5,
  "mood_date": "date-string",
  "created_at": "datetime"
}
```

### `journals`
```json
{
  "user_id": "uuid-string",
  "content": "string",
  "mood": "sad | okay | calm | happy | great",
  "sentiment_score": 0.72,
  "reflection": "AI-generated supportive reflection",
  "created_at": "datetime"
}
```

### `professional_links`
```json
{
  "user_id": "uuid-string",
  "professional_id": "uuid-string",
  "status": "pending | accepted | rejected",
  "allow_mood": false,
  "allow_journal": false,
  "created_at": "datetime",
  "accepted_at": "datetime"
}
```

### `crisis_alerts`
```json
{
  "user_id": "uuid-string",
  "chat_id": "uuid-string",
  "message": "The exact message that triggered detection",
  "detection_method": "keyword | llm",
  "resolved": false,
  "created_at": "datetime"
}
```

### `sessions`
```json
{
  "user_id": "uuid-string",
  "professional_id": "uuid-string",
  "session_date": "datetime",
  "session_type": "Consultation",
  "note": "string",
  "status": "pending | confirmed | rejected | completed",
  "created_at": "datetime"
}
```

### `professional_notes`
```json
{
  "professional_id": "uuid-string",
  "user_id": "uuid-string",
  "note": "string",
  "created_at": "datetime"
}
```

### `reports`
```json
{
  "user_id": "uuid-string",
  "report_text": "AI-generated wellness summary",
  "generated_at": "datetime"
}
```

---

## 🔐 Security

### Password Hashing
`passlib.CryptContext(schemes=["argon2", "bcrypt"], deprecated="auto")`
- **New registrations** → hashed with **Argon2** (stronger, modern algorithm)
- **Existing bcrypt hashes** → still verified automatically — no re-registration needed
- `deprecated="auto"` means passlib identifies the scheme from the stored hash

### JWT Authentication
- Library: `python-jose`
- Token payload: `{ "sub": "user@email.com", "role": "user|professional|admin", "exp": expiry_timestamp }`
- Created in `utils/security.py` → `create_access_token()`
- Verified in `routes/auth.py` → `get_current_user()` Depends used on all protected routes
- Returns `401 Unauthorized` if token is missing, expired, or tampered
- Admin routes use `require_admin()` on top → returns `403 Forbidden` if role ≠ admin

### Best Practices
- All secrets live in `.env` — never in source code
- Passwords never stored in plaintext
- Role enforced server-side on every request — never trusted from client
- Data sharing between user and professional requires explicit per-field consent (`allow_mood`, `allow_journal`)

---

## 🚨 Crisis Detection System

Runs **concurrently** with every chat response via `asyncio.gather()` — **zero latency impact** on normal conversations.

### Stage 1 — Instant Keyword Scan (`keyword_check`)
Checks message (lowercased) for any of these 15 keywords:

```
suicide          kill myself       end my life       want to die
don't want to live    self harm    self-harm         cut myself
hurt myself      no reason to live    better off dead    can't go on
give up on life  overdose         hang myself
```

If matched → **immediately flagged as crisis**. LLM call skipped entirely.

### Stage 2 — LLM Risk Assessment (`llm_crisis_check`)
Only runs if **no keyword** is found.

LangChain `ChatPromptTemplate | ChatHuggingFace` chain instructs Llama 3.1 to return:
```json
{
  "risk_level": "none | mild | moderate | severe",
  "reasoning": "one sentence explanation"
}
```

`is_crisis = True` if `risk_level` is `"moderate"` or `"severe"`.

### On Crisis Detected

**Step 1 —** `save_crisis_alert()` inserts into `crisis_alerts` collection:
```json
{
  "user_id": "...",
  "chat_id": "...",
  "message": "exact message that triggered",
  "detection_method": "keyword | llm",
  "resolved": false,
  "created_at": "datetime"
}
```

**Step 2 —** `build_crisis_response()` appends to bot response:
```
💙 I'm really concerned about your safety right now. Please know you're not alone.

Emergency Support Resources:
• iCall (India): 9152987821 — Mon–Sat, 8am–10pm
• Vandrevala Foundation: 1860-2662-345 — 24/7
• AASRA: 9820466627 — 24/7
• Crisis Text Line (Global): Text HOME to 741741 — 24/7

If you're in immediate danger, please call 112 (India emergency services).
```

**Step 3 —** Alert appears in:
- Admin panel → `GET /admin/crisis`
- Linked professional's dashboard → `GET /professional/crisis`

---

<div align="center">
  <sub>Backend API</sub>
</div>
---