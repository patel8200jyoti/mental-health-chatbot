# 🧠 MindMitra — Flutter Frontend
### Mobile & Web App · Capstone Project

> A cross-platform Flutter application for AI-powered mental health support.
> Connects to a **FastAPI + LangChain + Llama 3.1** backend via REST API with JWT authentication.
> Supports three user roles — **User**, **Professional**, and **Admin** — each with distinct screens and permissions.

---

## 📑 Table of Contents

1. [Project Overview](#-project-overview)
2. [Tech Stack](#-tech-stack)
3. [Project Structure](#-project-structure)
4. [Screens & Features](#-screens--features)
5. [Navigation & Routes](#-navigation--routes)
6. [API Service Layer](#-api-service-layer)
7. [Getting Started](#-getting-started)
8. [Configuration](#-configuration)
9. [App Icon & Branding](#-app-icon--branding)
10. [Team](#-team)

---

## 🔍 Project Overview

The MindMitra Flutter app is the client-side interface of an AI-powered mental health chatbot platform. It communicates with a FastAPI backend via REST API and supports three distinct user roles — User, Professional, and Admin — each with their own screens, navigation, and data access.

**Core features:**
- 🤖 **AI chatbot** — real-time messaging with Llama 3.1, persistent chat history, crisis detection with helpline display
- 📊 **Mood tracking** — daily emoji-based mood logging, bar graph with Day/Week/Month views, streak counter
- 📓 **Smart journal** — write entries with automatic AI emotion analysis (mood, sentiment score, reflection)
- 🧰 **Wellness toolkit** — grouped self-care content: breathing exercises, CBT activities, grounding techniques
- 👨‍⚕️ **Doctor portal** — browse professionals, send link requests, share mood/journal data, book sessions, send messages
- 👤 **AI wellness report** — auto-generated wellness summary from chat + mood + journal history
- 🏥 **Professional dashboard** — patient management, crisis alerts, mood/journal access, clinical notes
- 🔧 **Admin panel** — user management, professional verification, system stats, crisis monitoring

---

## 🛠 Tech Stack

| Category | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | StatefulWidget + setState |
| HTTP Client | Dio with JWT interceptor |
| Secure Storage | flutter_secure_storage |
| Navigation | Named routes via MaterialApp |
| Web URL Strategy | flutter_web_plugins (path URL strategy) |
| Target Platforms | Android · iOS · Web (Chrome) |

---

## 📁 Project Structure

```
lib/
│
├── main.dart                        # App entry point — MaterialApp, all named routes
│
├── models/
│   └── chat_message.dart            # ChatMessage, User, Report data classes
│
├── services/                        # All API communication lives here
│   ├── core/
│   │   └── api_service.dart         # ApiClient — Dio singleton + JWT interceptor
│   │                                # AppApi — user auth, chat, mood, journal, toolkit,
│   │                                #          profile, doctor linking, sessions, messages
│   ├── chat_api_service.dart        # AppApi re-export used by user screens
│   ├── professional_api.dart        # ProfessionalApi — all professional-role API calls
│   └── admin_api.dart               # AdminApi — all admin-role API calls
│
├── utils/
│   └── profile_doodle.dart          # ProfileDoodleIcon — custom avatar widget (CustomPainter)
│
└── screens/
    │
    ├── user/                        # All user-role screens
    │   ├── splash_screen.dart       # Landing screen — logo, feature cards, Create Account / Sign In
    │   ├── login_screen.dart        # Email + password login, role-based routing
    │   ├── signup_screen.dart       # Registration form + auto-login flow
    │   ├── chat_screen.dart         # AI chatbot — chat list sidebar, send message, history
    │   ├── mood_screen.dart         # Log mood, bar graph (Day/Week/Month tabs), streak counter
    │   ├── journal_screen.dart      # Journal list — create, view, delete entries
    │   ├── journal_entry_detail_screen.dart  # View + edit a single journal entry
    │   ├── ToolKit_screen.dart      # Grouped wellness tools with category tabs
    │   ├── findDoctor_screen.dart   # Browse approved professionals + send link request
    │   ├── my_doctor_page.dart      # Linked doctor — sessions, messages, data permissions
    │   └── profile_screen.dart      # Personal info + AI-generated wellness report
    │
    ├── professional/                # All professional-role screens
    │   ├── login_proff.dart         # Login + role/approval check + routing
    │   ├── signup_proff.dart        # Multi-step professional registration form
    │   ├── pending_proff.dart       # Waiting for admin approval screen
    │   ├── shell_proff.dart         # ProfessionalShell — BottomNavigationBar (4 tabs)
    │   ├── proff_dash.dart          # Dashboard — stats, pending requests, recent patients
    │   ├── proff_patients.dart      # Patient list — profile, mood history, journal access
    │   ├── proff_crisis.dart        # Crisis alerts for linked patients
    │   └── proff_analytics.dart     # Patient emotion analytics charts
    │
    └── admin/                       # All admin-role screens
        ├── admin_login.dart         # Admin credentials login
        ├── shell_admin.dart         # AdminShell — BottomNavigationBar (4 tabs)
        ├── admin_dashboard.dart     # System stats overview
        ├── admin_users.dart         # All registered users list
        ├── admin_doctors.dart       # Professionals list — verify / reject
        ├── admin_mood_journal.dart  # Platform mood trends + analytics
        └── proff_verification.dart  # Professional detail + approve/reject action
```

---

## 📱 Screens & Features

### User Role

#### Splash Screen (`/`)
- App logo (`Icons.spa` on teal `CircleAvatar`)
- **Mind***Ease* branding with tagline
- Floating feature preview cards (mood, breathing, streak)
- "Create Account" → `/signup` · "Sign In" → `/login`

#### Login Screen (`/login`)
- Email + password form with validation
- Role-based routing after login:
  - `admin@admin.com` → `/admin_dashboard`
  - All others → `/mood`
- "Login as Professional" → `/proff_login`

#### Signup Screen (`/signup`)
- Full name, email, password (with strength validation), DOB picker, gender picker
- Auto-login after successful registration → `/mood`
- "Already have an account?" → `/login`

#### Mood Screen (`/mood`)
- 5-emoji mood picker (Sad / Okay / Calm / Happy / Great)
- Optimistic UI — selection shows instantly, saves in background
- Bar graph with **Day / Week / Month** tabs:
  - Day: X axis = date labels, one bar per day
  - Week: X axis = ISO week numbers, averaged
  - Month: X axis = month name, averaged
- Y axis: Sad → Great labels aligned to grid lines via `CustomPainter`
- Streak counter (consecutive days logged)

#### Chat Screen (`/chat`)
- Sidebar: list of chat sessions (title auto-set from first message)
- Send messages, receive Llama 3.1 AI responses
- Crisis detection: if triggered, helpline numbers displayed inline
- Create new chat, clear chat, delete chat

#### Journal Screen (`/journal`)
- List of entries with AI-analysed mood + sentiment score badge
- Create new entry → auto AI analysis (mood, sentiment 0–1, supportive reflection)
- Tap entry → full detail view with edit + delete
- Re-analysis runs on every update

#### Toolkit Screen (`/toolkit`)
- Grouped wellness content: Breathing Exercises, CBT Activities, Grounding Techniques, Daily Tips, Self-Assessment
- Category tabs with card-based layout

#### Find Professional Screen (`/doctor`)
- Browse all approved professionals
- Send link request
- View pending / accepted links

#### My Doctor Page
- Linked professional's profile
- Toggle mood/journal data sharing permissions
- Request and view sessions
- Portal messaging

#### Profile Screen (`/profile`)
- Personal information display
- AI-generated wellness report (summarises chat + mood + journal history via Llama 3.1)
- Regenerate report button

---

### Professional Role

| Screen | Description |
|---|---|
| `ProffLogin` | Login → checks role + approval → routes to dashboard or pending |
| `ProffSignupScreen` | Multi-step form: personal info + medical registration details |
| `ProffPendingScreen` | Shown while waiting for admin to approve account |
| `ProfessionalShell` | 4-tab bottom nav: Dashboard · Patients · Crisis · Analytics |
| `ProfDashboard` | Stats summary, pending requests, recent patient activity |
| `ProfPatientsPage` | Patient list with profile, mood history, journal access (permission-gated) |
| `ProfCrisisPage` | Unresolved crisis alerts for linked patients |
| `ProfAnalyticsPage` | Emotion and mood trend charts across patient base |

---

### Admin Role

| Screen | Description |
|---|---|
| `AdminLogin` | Admin credentials (email: admin@admin.com) |
| `AdminShell` | 4-tab bottom nav: Dashboard · Users · Doctors · Mood/Journal |
| `AdminDashboard` | Platform-wide stats: users, professionals, pending approvals |
| `AdminUsersPage` | Full registered user list |
| `AdminDoctorsPage` | All professionals — approve or reject accounts |
| `AdminMoodJournalPage` | Platform mood trends, journal analytics |
| `ProffVerification` | Individual professional detail + approve/reject action |

---

## 🗺 Navigation & Routes

```
/                → SplashScreen
/login           → LoginScreen
/signup          → SignupScreen
/mood            → MoodScreen          ← user home after login
/chat            → ChatScreen
/journal         → JournalScreen
/toolkit         → ToolkitScreen
/doctor          → FindProfessionalScreen
/profile         → PersonalInformationScreen
/proff_login     → ProffLogin
/proff_signup    → ProffSignupScreen
/proff_pending   → ProffPendingScreen
/proff           → ProfessionalShell
/admin_login     → AdminLogin
/admin_dashboard → AdminShell
```

### Role routing after login

| Role | Condition | Destination |
|---|---|---|
| User | Default | `/mood` |
| Admin | email == admin@admin.com | `/admin_dashboard` |
| Professional | `is_approved == true` | `/proff` |
| Professional | `is_approved == false` | `/proff_pending` |

---

## 🔌 API Service Layer

All HTTP calls go through `lib/services/core/api_service.dart` which holds a **Dio singleton** with:
- Base URL configured once
- JWT `Authorization: Bearer <token>` injected on every request via interceptor
- Token stored in `flutter_secure_storage` — survives app restarts
- `validateStatus: (s) => s < 500` — 4xx responses return normally instead of throwing

### Three API classes

| Class | File | Used By |
|---|---|---|
| `AppApi` | `services/chat_api_service.dart` | All user screens |
| `ProfessionalApi` | `services/professional_api.dart` | Professional screens |
| `AdminApi` | `services/admin_api.dart` | Admin screens |

### AppApi methods

| Method | Endpoint | Description |
|---|---|---|
| `login()` | `POST /auth/login` | Returns JWT, saves to secure storage |
| `register()` | `POST /auth/register` | Creates user account |
| `getWeekMood()` | `GET /mood/week` | Last 7 days mood data |
| `getAllMoods()` | `GET /mood/all` | Full mood history |
| `getMoodStats()` | `GET /mood/stats` | Aggregated daily/weekly/monthly |
| `addMood()` | `POST /mood/` | Log mood for today |
| `getStreak()` | `GET /mood/streak` | Consecutive day streak |
| `getJournals()` | `GET /journal/` | All journal entries |
| `addJournal()` | `POST /journal/` | Create entry (AI analysis auto-runs) |
| `updateJournal()` | `PUT /journal/{id}` | Update entry (re-analysis) |
| `deleteJournal()` | `DELETE /journal/{id}` | Delete entry |
| `getGroupedTools()` | `GET /toolkit/grouped` | Wellness tools by category |
| `getProfile()` | `GET /profile/me` | User profile |
| `getReport()` | `GET /profile/report/me` | AI wellness report |
| `regenerateReport()` | `POST /profile/report/me` | Regenerate report |
| `getProfessionals()` | `GET /professional/` | Browse approved professionals |
| `requestProfessional()` | `POST /professional/request` | Send link request |
| `getMyLinks()` | `GET /my-doctor/links` | All link records |
| `updateLinkPermissions()` | `PUT /my-doctor/link/{id}/permissions` | Toggle mood/journal sharing |
| `getSessions()` | `GET /my-doctor/{id}/sessions` | Sessions list |
| `requestSession()` | `POST /my-doctor/{id}/sessions` | Book a session |
| `getPortalMessages()` | `GET /my-doctor/{id}/messages` | Portal messages |
| `sendPortalMessage()` | `POST /my-doctor/{id}/messages` | Send portal message |
| `logout()` | — | Clears all stored tokens |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x+
- Dart 3.x+
- Android Studio / Xcode (for device/emulator)
- Backend server running (see backend README)

### Installation

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd frontend

# 2. Install dependencies
flutter pub get

# 3. Run on your target
flutter run                    # default connected device
flutter run -d chrome          # web
flutter run -d emulator-5554   # Android emulator
```

---

## ⚙️ Configuration

### Backend URL

Open `lib/services/core/api_service.dart` and set the base URL:

```dart
// Android Emulator  → http://10.0.2.2:8000
// Real Device       → http://YOUR_LOCAL_IP:8000  (same Wi-Fi as server)
// Production        → https://your-backend.com
static const String baseUrl = "http://YOUR_IP:8000";
```

> **Real device testing:** your phone and the backend machine must be on the same Wi-Fi network. Use your machine's local IP (e.g. `192.168.x.x`), not `localhost`.

---

## 🎨 App Icon & Branding

**Logo:** `Icons.spa` (Flutter material icon) inside a teal `CircleAvatar` — used consistently across splash, login, signup, and app bar.

**App name:** MindMitra

**Colour palette:**
| Use | Hex |
|---|---|
| Primary teal | `#4FBFA5` |
| Light mint | `#B2F1E8` |
| Background | `#F4F8FB` |
| Card blue tint | `#EAF4FF` |

**Web icons** — replace files in `web/` with your teal spa icon:
```
web/favicon.png                   (32×32)
web/icons/Icon-192.png            (192×192)
web/icons/Icon-512.png            (512×512)
web/icons/Icon-maskable-192.png   (192×192)
web/icons/Icon-maskable-512.png   (512×512)
```

**App name in browser** — update `web/manifest.json`:
```json
"name": "MindMitra",
"short_name": "MindMitra"
```

And `web/index.html`:
```html
<title>MindMitra</title>
```

**Android app name** — update `android/app/src/main/AndroidManifest.xml`:
```xml
android:label="MindMitra"
```

---

## 👥 Team

Kanani Zainab · Patel Jyoti Bansilal · Parekh Vrunda Nirajbhai