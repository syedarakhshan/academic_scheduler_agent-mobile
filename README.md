# Academic Scheduler Agent (TimeCade) — Mobile App

A Flutter mobile app for the **Academic Scheduler Agent** timetable system. It gives **teachers** and **students** quick access to their weekly timetable, notifications and an AI scheduling assistant, and lets them export their timetable as a colorful PDF.

This is the mobile companion of the TimeCade web application and talks to the same backend API.

---

## Features

### Both roles
- Login with **JUW ID + password**
- Role-based home screen (Teacher or Student), restored automatically on app launch
- Secure token storage (encrypted on-device)
- Notifications with unread badge
- Profile settings and **Change Password**
- Logout with confirmation
- Animated splash screen with the app logo
- **Export timetable as PDF** (colored weekly grid + class list) and share it from the phone

### Teacher
- **Dashboard**
- **My Schedule** with two views you can switch between:
  - **List** — classes grouped day-wise, colored by subject
  - **Grid** — day × time-slot grid where 3-hour labs span 3 columns
- **Reschedule request** for any class (from the list or by tapping a class in the grid)
- **AI Agent** — chat with the scheduling assistant

### Student
- **Dashboard**
- **Timetable** — weekly grid with a color per subject
- **My Courses**

> Office-assistant accounts can sign in but are told this app only supports teachers and students.

---

## Tech stack

| Area | Package |
|---|---|
| Framework | Flutter (Dart `>=3.0.0 <4.0.0`) |
| State management | `provider` |
| Networking | `dio` (JWT attached to every request, auto-logout on 401) |
| Secure storage | `flutter_secure_storage` |
| PDF export | `pdf`, `printing`, `share_plus`, `path_provider` |
| Dates / icons | `intl`, `lucide_icons` |
| Font | Plus Jakarta Sans |

The backend is a separate service (Node.js / Express with a PostgreSQL database) that is shared with the web app.

---

## Project structure

```
lib/
├── main.dart                  # App entry + role-based root router
├── core/
│   ├── api/                   # Dio client, token storage, API services
│   ├── constants/             # app_config.dart (API base URL)
│   ├── pdf/                   # Timetable PDF generation
│   └── theme/                 # Navy/teal theme
├── models/                    # AppUser, TimetableEntry, notifications, ...
├── providers/                 # AuthProvider (login, logout, session restore)
└── screens/
    ├── auth/                  # Login
    ├── common/                # Notifications sheet, profile settings
    ├── student/               # Student shell, dashboard, timetable, courses
    ├── teacher/               # Teacher shell, dashboard, schedule, AI agent
    └── splash_screen.dart
assets/
├── fonts/                     # Plus Jakarta Sans
└── images/                    # App logo
```

---

## Getting started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Android Studio (or VS Code) with an Android emulator or a physical Android phone
- The TimeCade backend running or deployed, with at least one teacher or student account

### 1. Clone and install

```bash
git clone https://github.com/syedarakhshan/academic_scheduler_agent-mobile.git
cd academic_scheduler_agent-mobile
flutter pub get
```

### 2. Point the app at your backend

Open `lib/core/constants/app_config.dart` and set `apiBaseUrl` to your backend address.

- **Deployed backend (HTTPS):** use the deployed URL. Nothing else is needed.
- **Local backend on the Android emulator:** the emulator reaches your computer at `10.0.2.2`, not `localhost`.
- **Local backend over plain `http://`:** Android 9+ blocks cleartext traffic by default. For development only, add a network security config:

  `android/app/src/main/res/xml/network_security_config.xml`

  ```xml
  <?xml version="1.0" encoding="utf-8"?>
  <network-security-config>
      <domain-config cleartextTrafficPermitted="true">
          <domain includeSubdomains="true">10.0.2.2</domain>
          <domain includeSubdomains="true">localhost</domain>
      </domain-config>
  </network-security-config>
  ```

  Then reference it inside the `<application>` tag of `android/app/src/main/AndroidManifest.xml`:

  ```xml
  android:networkSecurityConfig="@xml/network_security_config"
  ```

### 3. Run

```bash
flutter run
```

Sign in with an existing teacher or student account from your database.

### Build an APK

```bash
flutter build apk --release
```

The APK is created at `build/app/outputs/flutter-apk/app-release.apk`.

---

## Notes

- Developed and tested on Android. The iOS, web, Windows, macOS and Linux folders are the default Flutter platform scaffolding.
- Keep secrets (API keys, signing keystores, `key.properties`) out of the repository. They are already covered by `.gitignore`.

---

## Author

**Rakhshan** — [@syedarakhshan](https://github.com/syedarakhshan)
