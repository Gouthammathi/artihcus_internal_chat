# ⚡ Quick Reference - App Structure

## 🎯 Where Everything Is

### **Main Files**
- **App Start**: `lib/main.dart`
- **App Config**: `lib/app.dart`
- **Routes**: `lib/core/routing/app_router.dart`
- **Main Screen**: `lib/features/home/presentation/home_page.dart`

### **Bottom Navigation** (2 tabs)
- **Home Tab**: `lib/features/home/presentation/home_page.dart` (line 78-94)
- **Profile Tab**: `lib/features/profile/presentation/profile_page.dart`

### **Feature Pages** (Opened from cards)
- **Attendance**: `lib/features/attendance/presentation/attendance_page.dart`
- **Announcements**: `lib/features/home/presentation/tabs/announcements_tab.dart`
- **Teams**: `lib/features/home/presentation/tabs/teams_tab.dart`
- **Leave Apply**: `lib/features/home/presentation/tabs/leave_apply_tab.dart`

### **Auth Pages**
- **Login**: `lib/features/auth/presentation/login_page.dart`
- **Signup**: `lib/features/auth/presentation/signup_page.dart`

---

## 📱 Page Types

| Type | Location | How to Access |
|------|----------|---------------|
| **Bottom Nav** | `home_page.dart` | Tap bottom icons |
| **Feature Cards** | `home_page.dart` | Tap cards on home screen |
| **Feature Pages** | `features/[name]/presentation/` | Opened from cards |
| **Auth Pages** | `features/auth/presentation/` | Shown when not logged in |

---

## 🔧 Common Tasks

### Add a new feature page:
1. Create: `lib/features/[name]/presentation/[name]_page.dart`
2. Add route in: `lib/core/routing/app_router.dart`
3. (Optional) Add card in: `home_page.dart` line 22-59

### Modify bottom navigation:
- Edit: `lib/features/home/presentation/home_page.dart` (line 78-94)

### Change app theme:
- Edit: `lib/core/theme/app_theme.dart`

### Change routes:
- Edit: `lib/core/routing/app_router.dart`

---

## 📂 Folder Structure

```
lib/
├── main.dart ⭐ START
├── app.dart
├── core/ (routing, theme, config)
└── features/
    ├── home/ 🏠 (Main screen with bottom nav)
    ├── profile/ 👤 (Profile tab)
    ├── auth/ 🔐 (Login/Signup)
    ├── attendance/ ✅ (Attendance feature)
    └── [other features]/
```

---

## 🎨 Visual Flow

```
App Start → Login → HomePage
                      │
                      ├─→ Home Tab (Feature Cards)
                      │   ├─→ Attendance
                      │   ├─→ Announcements
                      │   ├─→ Teams
                      │   └─→ Leave Apply
                      │
                      └─→ Profile Tab
```

---

**For detailed explanation, see `APP_STRUCTURE.md`**

