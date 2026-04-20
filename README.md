# 🧠 MindMitra — Flutter Frontend
**Flutter · Dart · FastAPI Backend**
> Capstone Project

---

## Tech Stack
| | |
|---|---|
| Framework | Flutter (Dart) |
| State | StatefulWidget + setState |
| HTTP | Dio (JWT interceptor) |
| Storage | flutter_secure_storage |
| Navigation | Named routes (MaterialApp) |
| Target | Android · iOS · Web (Chrome) |

---

## Setup
```bash
git clone <repo-url> && cd frontend
flutter pub get
flutter run
```

> Make sure your backend server is running and update the base URL in `lib/services/core/api_service.dart`

---

## Project Structure
```
lib/
├── main.dart                        # App entry — MaterialApp, all named routes
├── models/
│   └── chat_message.dart            # ChatMessage, User, Report data classes
├── services/
│   ├── core/
│   │   └── api_service.dart         # ApiClient — Dio singleton + JWT interceptor
│   ├── chat_api_service.dart        # AppApi — user auth, chat, mood, journal, toolkit, doctor
│   ├── professional_api.dart        # ProfessionalApi — professional-role API calls
│   └── admin_api.dart               # AdminApi — admin-role API calls
├── utils/
│   └── profile_doodle.dart          # ProfileDoodleIcon widget
└── screens/
    ├── user/                        # User screens
    │   ├── splash_screen.dart       # Landing screen with Create Account / Sign In
    │   ├── login_screen.dart        # Email + password login
    │   ├── signup_screen.dart       # Registration with auto-login
    │   ├── chat_screen.dart         # AI chatbot — send messages, view history
    │   ├── mood_screen.dart         # Log mood, bar graph (Day/Week/Month), streak
    │   ├── journal_screen.dart      # Create, view, delete journal entries
    │   ├── ToolKit_screen.dart      # Grouped wellness tools
    │   ├── findDoctor_screen.dart   # Browse + link professionals
    │   ├── my_doctor_page.dart      # Linked doctor, sessions, messages, permissions
    │   └── profile_screen.dart      # Profile + AI wellness report
    ├── professional/                # Professional screens
    │   ├── login_proff.dart         # Professional login + role check
    │   ├── signup_proff.dart        # Multi-step professional registration
    │   ├── pending_proff.dart       # Waiting for admin approval
    │   ├── shell_proff.dart         # Bottom nav shell (4 tabs)
    │   ├── proff_dash.dart          # Dashboard — stats, pending requests
    │   ├── proff_patients.dart      # Patient list, mood, journals
    │   ├── proff_crisis.dart        # Crisis alerts
    │   └── proff_analytics.dart     # Patient emotion analytics
    └── admin/                       # Admin screens
        ├── admin_login.dart         # Admin login
        ├── shell_admin.dart         # Admin bottom nav shell
        ├── admin_dashboard.dart     # System stats
        ├── admin_users.dart         # All users
        ├── admin_doctors.dart       # Professionals — verify/reject
        ├── admin_mood_journal.dart  # Mood trends + analytics
        └── proff_verification.dart  # Professional detail + approve
```

---

## Routes
```
/             → SplashScreen
/login        → LoginScreen
/signup       → SignupScreen
/mood         → MoodScreen          (user home after login)
/chat         → ChatScreen
/journal      → JournalScreen
/toolkit      → ToolkitScreen
/doctor       → FindProfessionalScreen
/profile      → PersonalInformationScreen
/proff_login  → ProffLogin
/proff_signup → ProffSignupScreen
/proff        → ProfessionalShell
/admin_login  → AdminLogin
/admin_dashboard → AdminShell
```

---

## User Roles
| Role | Login Route | Home After Login |
|---|---|---|
| User | `/login` | `/mood` |
| Professional | `/proff_login` | `/proff` |
| Admin | `/login` (email: admin@admin.com) | `/admin_dashboard` |

---

## API Connection
Update the base URL in `lib/services/core/api_service.dart`:
```dart
// Android Emulator  → http://10.0.2.2:8000
// Real Device       → http://YOUR_LOCAL_IP:8000
// Production        → https://your-backend.com
static const String baseUrl = "http://YOUR_IP:8000";
```

---

## Team
Kanani Zainab · Patel Jyoti Bansilal · Parekh Vrunda Nirajbhai