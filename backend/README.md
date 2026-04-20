# 🧠 The MindMitra — Backend API
**FastAPI · LangChain · Llama 3.1 · MongoDB Atlas**
> Capstone Project 

---

## Tech Stack
| | |
|---|---|
| Framework | FastAPI + Uvicorn |
| AI | LangChain + Meta Llama 3.1-8B (HuggingFace) |
| Database | MongoDB Atlas (Motor async) |
| Auth | JWT (`python-jose`) + Argon2 (`passlib`) |
| Config | `pydantic-settings` |

---

## Setup
```bash
git clone <repo-url> && cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
```

Swagger docs → `http://localhost:8000/docs`

---

## .env
```env
MONGODB_URL=mongodb+srv://...
DATABASE_NAME=mhc
SECRET_KEY=your_secret
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_HOURS=84
HUGGINGFACEHUB_API_TOKEN=hf_...
HUGGING_FACE_MODEL=meta-llama/Llama-3.1-8B-Instruct
```

---

## Project Structure
```
backend/
├── main.py              # App entry, routers, CORS, startup/shutdown
├── config.py            # All env vars via pydantic BaseSettings
├── database.py          # Motor MongoDB singleton + get_database()
│
├── routes/              # Endpoints → call services
│   ├── auth.py          # /auth/register  /auth/login  get_current_user()
│   ├── chat.py          # /chat/ CRUD + send message (LangChain pipeline)
│   ├── mood.py          # /mood/ log + stats + streak
│   ├── journal.py       # /journal/ CRUD (auto AI analysis on save)
│   ├── profile.py       # /profile/me  /profile/report/me
│   ├── toolkit.py       # /toolkit/ static wellness content
│   ├── professional.py  # Professional dashboard, patients, crisis, notes
│   ├── user_proff.py    # /my-doctor/ links, sessions, messages
│   └── admin.py         # Stats, verify professionals, crisis alerts
│
├── services/            # Business logic → call utils + DB
│   ├── chat_service.py      # chat_with_bot() — full AI pipeline
│   ├── journal_service.py   # calls analyse_journal() on every save
│   ├── crisis_service.py    # save_crisis_alert() + build_crisis_response()
│   └── ...
│
├── utils/               # AI + security tools → called by services
│   ├── memory_history.py    # MongoDB-backed LangChain chat memory
│   ├── emotion_detector.py  # analyse_journal() + analyse_chats() via Llama
│   ├── crisis_detector.py   # keyword scan → LLM risk check
│   ├── report_generator.py  # AI wellness report from chats + journals
│   └── security.py          # hash, verify, JWT create/verify
│
├── models/              # Pydantic — validates request bodies
├── schemas/             # Converts MongoDB docs ↔ response dicts
└── data/
    └── toolkit_data.py  # Static toolkit content (no DB needed)
```

---

## API Routes

## 🗺 API Flow Map

| Action | Method | Endpoint | Calls Service | Uses Util |
|---|---|---|---|---|
| Register user | `POST` | `/auth/register` | `auth_service.create_user()` | `security.hash_password()` |
| Login | `POST` | `/auth/login` | `auth_service.get_user()` | `security.verify_password()` `security.create_access_token()` |
| Create chat session | `POST` | `/chat/` | — | — |
| Send message | `POST` | `/chat/{chat_id}` | `chat_service.chat_with_bot()` | `memory_history.load_message()` `crisis_detector.detect_crisis()` `emotion_detector.analyse_chats()` |
| Get chat list | `GET` | `/chat/list` | — | — |
| Get chat messages | `GET` | `/chat/{chat_id}` | — | — |
| Delete chat | `DELETE` | `/chat/{chat_id}` | — | — |
| Log mood | `POST` | `/mood/` | `mood_service.create_mood()` | — |
| Get weekly mood | `GET` | `/mood/week` | `mood_service.get_week_moods()` | — |
| Get mood stats | `GET` | `/mood/stats` | `mood_service.get_mood_stats()` | — |
| Get streak | `GET` | `/mood/streak` | `mood_service.calculate_streak()` | — |
| Create journal | `POST` | `/journal/` | `journal_service.create_journal()` | `emotion_detector.analyse_journal()` |
| Update journal | `PUT` | `/journal/{id}` | `journal_service.update_journal()` | `emotion_detector.analyse_journal()` |
| Delete journal | `DELETE` | `/journal/{id}` | `journal_service.delete_journal()` | — |
| Get toolkit | `GET` | `/toolkit/grouped` | `toolkit_services.get_grouped()` | — |
| Get profile | `GET` | `/profile/me` | `profile_service.get_user_profile()` | — |
| Get AI report | `GET` | `/profile/report/me` | `profile_service.get_report()` | `report_generator.generate_final_report()` |
| Regenerate report | `POST` | `/profile/report/me` | `profile_service.generate_report()` | `report_generator.summarize_chats()` |
| Register professional | `POST` | `/professional/register` | — | `security.hash_password()` |
| Browse professionals | `GET` | `/professional/` | `professional_service.list_professionals()` | — |
| Send link request | `POST` | `/professional/request` | `professional_service.request_professional()` | — |
| Get dashboard stats | `GET` | `/professional/dashboard/stats` | `professional_service.get_dashboard_stats()` | — |
| Get patients | `GET` | `/professional/patients` | `professional_service.get_patients()` | — |
| Get pending requests | `GET` | `/professional/patients/pending` | `professional_service.get_pending_requests()` | — |
| Accept / reject request | `POST` | `/professional/patients/{id}/respond` | `professional_service.respond_to_request()` | — |
| Unlink patient | `DELETE` | `/professional/patients/{id}` | `professional_service.remove_patient()` | — |
| View patient profile | `GET` | `/professional/patients/{id}/profile` | `professional_service.get_patient_profile()` | — |
| View patient moods | `GET` | `/professional/patients/{id}/moods` | `professional_service.get_patient_moods()` | — |
| View patient journals | `GET` | `/professional/patients/{id}/journals` | `professional_service.get_patient_journals()` | — |
| Get crisis alerts (prof) | `GET` | `/professional/crisis` | `crisis_service.get_crisis_alerts()` | — |
| Resolve crisis | `POST` | `/professional/crisis/{id}/resolve` | `crisis_service.resolve_crisis()` | — |
| Add patient note | `POST` | `/professional/patients/{id}/notes` | `professional_service.add_note()` | — |
| Delete patient note | `DELETE` | `/professional/patients/{id}/notes/{note_id}` | `professional_service.delete_note()` | — |
| Get my links | `GET` | `/my-doctor/links` | `professional_service.get_my_links()` | — |
| Get link info | `GET` | `/my-doctor/link/{id}` | `professional_service.get_link_with()` | — |
| Update permissions | `PUT` | `/my-doctor/link/{id}/permissions` | `professional_service.update_permissions()` | — |
| Unlink professional | `DELETE` | `/my-doctor/link/{id}` | `professional_service.unlink_professional()` | — |
| Cancel request | `DELETE` | `/my-doctor/request/{id}` | `professional_service.cancel_request()` | — |
| View prof profile | `GET` | `/my-doctor/{id}/profile` | `professional_service.get_prof_profile()` | — |
| Request session | `POST` | `/my-doctor/{id}/sessions` | `professional_service.request_session()` | — |
| Get sessions | `GET` | `/my-doctor/{id}/sessions` | `professional_service.get_sessions()` | — |
| Send portal message | `POST` | `/my-doctor/{id}/messages` | `professional_service.send_message()` | — |
| Get portal messages | `GET` | `/my-doctor/{id}/messages` | `professional_service.get_messages()` | — |
| Admin stats | `GET` | `/admin/stats` | `admin_service.get_stats()` | — |
| Admin dashboard stats | `GET` | `/admin/stats/dashboard` | `admin_service.get_dashboard_stats()` | — |
| Mood trends | `GET` | `/admin/stats/moods` | `admin_service.get_mood_trends()` | — |
| All users | `GET` | `/admin/users` | `admin_service.get_all_users()` | — |
| All professionals | `GET` | `/admin/professionals` | `admin_service.get_all_professionals()` | — |
| Verify professional | `PUT` | `/admin/professionals/{id}/verify` | `admin_service.verify_professional()` | — |
| Reject professional | `PUT` | `/admin/professionals/{id}/reject` | `admin_service.reject_professional()` | — |
| Get crisis alerts (admin) | `GET` | `/admin/crisis` | `admin_service.get_crisis_alerts()` | — |

> 🔒 All routes except `/auth/register`, `/auth/login`, `GET /professional/`, and `POST /professional/register` require `Authorization: Bearer <token>`

---

## How It Works

**Every request:**
```
Flutter → routes/ (JWT check) → services/ (logic) → utils/ (AI/security) → MongoDB
```

**Chat pipeline:**
```
Message → load history from MongoDB → [SystemMessage + history + HumanMessage]
        → asyncio.gather(detect_crisis(), model.ainvoke())
        → save messages → crisis? append helplines : return response
```

**Journal save:**
```
Content → analyse_journal() via LangChain → Llama returns {mood, sentiment, reflection}
        → saved to MongoDB alongside journal content
```

**Crisis detection (2 stages, runs concurrently with chat):**
```
Stage 1 → keyword scan (15 keywords, instant)
Stage 2 → LLM risk check if no keyword (none/mild/moderate/severe)
Crisis  → saved to crisis_alerts + helplines appended to response
```

---

## Collections
`users` · `chats` · `chat_messages` · `moods` · `journals` · `professional_links` · `crisis_alerts` · `sessions` · `professional_notes` · `reports`

---

## Team
Kanani Zainab · Patel Jyoti Bansilal · Parekh Vrunda Nirajbhai
