# TimeCade Mobile — Step 1: Project Setup

Teacher + Student panels only, reusing your existing `juw-timetable` backend
and PostgreSQL database as-is. No backend changes are required.

## Why you need one local step first

Flutter's SDK isn't available in the environment I built this in, so I
couldn't run `flutter create` myself. You'll need to generate the native
Android/iOS project shell once, then drop these files in.

### 1. Generate the Flutter project shell

```bash
flutter create timecade_mobile
```

This creates `android/`, `ios/`, `web/`, etc. — the platform boilerplate
that's impractical to hand-write.

### 2. Copy these files in, overwriting the generated defaults

- `pubspec.yaml` → project root
- `lib/` → replace the generated `lib/` folder entirely

### 3. Install dependencies

```bash
cd timecade_mobile
flutter pub get
```

### 4. Allow cleartext HTTP on Android (dev only)

Your backend runs on plain `http://` on localhost. Android 9+ blocks
cleartext traffic by default, so add a network security config:

`android/app/src/main/res/xml/network_security_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">10.0.2.2</domain>
        <domain includeSubdomains="true">localhost</domain>
    </domain-config>
</network-security-config>
```

Then reference it in `android/app/src/main/AndroidManifest.xml`, inside
the `<application>` tag:
```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```
(This is dev-only scaffolding — once the backend is deployed behind
HTTPS, none of this is needed and you'd just update `AppConfig.apiBaseUrl`.)

### 5. Start your backend

```bash
cd juw-timetable/backend
npm run dev
```
It needs to be reachable at `http://localhost:5000` on your host machine
(the app auto-translates this to `10.0.2.2` for the Android emulator —
see `lib/core/constants/app_config.dart` for details, including the
physical-device case).

### 6. Run the app

```bash
flutter run
```
Log in with any existing **teacher** or **student** account from your
`users` table — office-assistant accounts will log in but are told
this app doesn't support that role, matching the scope you asked for.

---

## What's built in Step 1

- Full project structure (`core/api`, `core/theme`, `models`, `providers`, `screens`)
- `ApiClient` (Dio) — mirrors `utils/api.js`: base URL, 60s timeout, JWT
  attached to every request, auto-logout on 401
- `TokenStorage` — encrypted on-device storage, replacing `localStorage`
- `AuthProvider` — mirrors `AuthContext.js`: `login()`, `logout()`,
  `changePassword()`, session restore on launch
- `AppUser` model — matches the exact `login`/`me` response shape
- Login screen — same JUW ID + password flow
- Role-based root router — Teacher/Student split like `App.js`'s
  `ProtectedRoute` + `RoleRedirect`
- Navy/teal theme matching the web app's branding
- Bottom-nav shells for Teacher (Dashboard, Schedule, Batches, Rooms,
  AI Agent) and Student (Dashboard, Timetable, My Courses) — **tab
  bodies are placeholders**, built out in the next steps

## Next steps (once you confirm Step 1 runs and logs in correctly)

5. Teacher: Dashboard + My Schedule
6. Teacher: Batch Timetable + Room Status
7. Teacher: Reschedule request + approval status
8. Teacher: AI Agent chat
9. Student: Dashboard + Timetable
10. Student: My Courses
11. Polish (loading/error states, pull-to-refresh, PDF export)
