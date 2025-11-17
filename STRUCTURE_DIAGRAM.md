# 📊 Visual Structure Diagram

## 🚀 App Launch Flow

```
┌─────────────────┐
│   main.dart     │ ← App starts here
│  (Entry Point)  │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│    app.dart     │ ← Sets up theme & router
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  app_router.dart│ ← Defines routes & auth
└────────┬────────┘
         │
         ├─→ Not logged in? → LoginPage
         │
         └─→ Logged in? → HomePage
```

---

## 🏠 HomePage Structure (Main Screen)

```
┌─────────────────────────────────────────────┐
│           HomePage (Main Screen)             │
├─────────────────────────────────────────────┤
│                                             │
│  Welcome, sandesh 👋                       │
│  Pick a workspace feature to continue.      │
│                                             │
│  ┌──────────────┐  ┌──────────────┐       │
│  │ Attendance   │  │Announcements │       │
│  │ Scan to mark │  │Latest updates│       │
│  └──────┬───────┘  └──────┬───────┘       │
│         │                 │                │
│         ↓                 ↓                │
│  AttendancePage   AnnouncementsTab         │
│                                             │
│  ┌──────────────┐  ┌──────────────┐       │
│  │   Teams      │  │ Leave Apply  │       │
│  │ People/roles │  │Request time │       │
│  └──────┬───────┘  └──────┬───────┘       │
│         │                 │                │
│         ↓                 ↓                │
│    TeamsTab        LeaveApplyTab           │
│                                             │
├─────────────────────────────────────────────┤
│  🏠 Home Tab    │    👤 Profile Tab      │ ← Bottom Navigation
└─────────────────────────────────────────────┘
```

---

## 📱 Bottom Navigation Tabs

```
HomePage (Bottom Navigation Bar)
│
├─→ Tab 0: Home Tab
│   └─→ Shows: Feature Cards Grid
│       ├─→ Attendance Card
│       ├─→ Announcements Card
│       ├─→ Teams Card
│       └─→ Leave Apply Card
│
└─→ Tab 1: Profile Tab
    └─→ Shows: ProfilePage
        └─→ User profile information
```

---

## 📂 File Organization

```
lib/
│
├── main.dart ⭐ START
│
├── app.dart
│
├── core/
│   └── routing/
│       └── app_router.dart 📍 Routes
│
└── features/
    │
    ├── home/ 🏠 MAIN SCREEN
    │   └── presentation/
    │       └── home_page.dart ⭐ Bottom Nav Here
    │
    ├── profile/ 👤 BOTTOM NAV TAB
    │   └── presentation/
    │       └── profile_page.dart
    │
    ├── auth/ 🔐 LOGIN/SIGNUP
    │   └── presentation/
    │       ├── login_page.dart
    │       └── signup_page.dart
    │
    ├── attendance/ ✅ FEATURE PAGE
    │   └── presentation/
    │       └── attendance_page.dart
    │
    ├── home/tabs/ 📋 FEATURE TABS
    │   ├── announcements_tab.dart
    │   ├── teams_tab.dart
    │   └── leave_apply_tab.dart
    │
    └── [other features]...
```

---

## 🔄 Page Types Explained

### Type 1: Bottom Navigation Pages
**Always visible at bottom of screen**

```
┌─────────────────────┐
│                     │
│   Page Content      │
│                     │
├─────────────────────┤
│ 🏠 Home │ 👤 Profile│ ← Always here
└─────────────────────┘
```

**Files:**
- `home_page.dart` - Contains the bottom nav
- `profile_page.dart` - Profile tab content

---

### Type 2: Feature Pages
**Opened from feature cards**

```
Home Screen
    │
    ├─→ Tap "Attendance" Card
    │   └─→ Opens AttendancePage (full screen)
    │
    ├─→ Tap "Announcements" Card
    │   └─→ Opens AnnouncementsTab (full screen)
    │
    └─→ Tap "Teams" Card
        └─→ Opens TeamsTab (full screen)
```

**Files:**
- `attendance_page.dart`
- `announcements_tab.dart`
- `teams_tab.dart`
- `leave_apply_tab.dart`

---

### Type 3: Auth Pages
**Shown before login**

```
App Start
    │
    └─→ Not logged in?
        └─→ LoginPage
            └─→ SignupPage (optional)
```

**Files:**
- `login_page.dart`
- `signup_page.dart`

---

## 🎯 Navigation Paths

### Path 1: App Launch (Not Logged In)
```
main.dart
  → app.dart
    → app_router.dart
      → LoginPage
        → (After login)
          → HomePage
```

### Path 2: App Launch (Already Logged In)
```
main.dart
  → app.dart
    → app_router.dart
      → HomePage
        → (User sees feature cards)
```

### Path 3: User Taps Feature Card
```
HomePage (Home Tab)
  → User taps "Attendance" card
    → Navigator.push()
      → AttendancePage (opens full screen)
```

### Path 4: User Switches Bottom Tab
```
HomePage
  → User taps "Profile" icon
    → setState() changes _selectedNavIndex
      → ProfilePage shown
```

---

## 📍 Key Locations

| What You Want | Where to Find It |
|---------------|------------------|
| **Bottom Navigation** | `lib/features/home/presentation/home_page.dart` (line 78-94) |
| **Feature Cards** | `lib/features/home/presentation/home_page.dart` (line 22-59) |
| **App Routes** | `lib/core/routing/app_router.dart` |
| **Profile Page** | `lib/features/profile/presentation/profile_page.dart` |
| **Attendance Page** | `lib/features/attendance/presentation/attendance_page.dart` |
| **Login Page** | `lib/features/auth/presentation/login_page.dart` |

---

## 🎨 Visual Page Hierarchy

```
App
│
├── Auth Flow (Not Logged In)
│   ├── LoginPage
│   └── SignupPage
│
└── Main App (Logged In)
    └── HomePage (Bottom Navigation)
        │
        ├── Home Tab
        │   └── Feature Cards Grid
        │       ├── Attendance Card → AttendancePage
        │       ├── Announcements Card → AnnouncementsTab
        │       ├── Teams Card → TeamsTab
        │       └── Leave Apply Card → LeaveApplyTab
        │
        └── Profile Tab
            └── ProfilePage
```

---

## 💡 Quick Tips

1. **Bottom Nav is in HomePage**: The bottom navigation bar is part of `home_page.dart`, not a separate file.

2. **Feature Cards are in HomePage**: The 4 feature cards are defined in `home_page.dart` as a list.

3. **Tabs vs Pages**: 
   - "Tabs" (like `announcements_tab.dart`) are simpler content widgets
   - "Pages" (like `attendance_page.dart`) are full-screen pages with app bars

4. **Navigation**: 
   - Bottom nav uses `setState()` to switch tabs
   - Feature cards use `Navigator.push()` to open new pages

5. **Everything is in `features/`**: Each feature has its own folder with controllers, models, and presentation files.

