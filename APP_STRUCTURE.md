# 📱 Artihcus Internal Chat - App Structure Guide

This document explains the file structure and navigation flow of the app in a simple, easy-to-understand way.

---

## 🎯 Quick Overview

```
App Flow:
main.dart → app.dart → app_router.dart → HomePage (with bottom nav)
                                              ↓
                    ┌────────────────────────┴────────────────────────┐
                    ↓                        ↓                         ↓
            Home Tab (Grid)          Profile Tab              Feature Pages
         (4 Feature Cards)        (ProfilePage)        (Attendance, Chat, etc.)
```

---

## 📂 Main Entry Points

### 1. **`lib/main.dart`** - App Starts Here
- **What it does**: Initializes the app
- **Key code**: 
  ```dart
  void main() {
    SupabaseConfig.initialize();  // Connect to database
    runApp(ArtihcusApp());        // Start the app
  }
  ```

### 2. **`lib/app.dart`** - App Configuration
- **What it does**: Sets up theme and router
- **Contains**: MaterialApp with theme and routing

### 3. **`lib/core/routing/app_router.dart`** - Navigation Routes
- **What it does**: Defines all app routes (pages)
- **Routes defined**:
  - `/login` → LoginPage
  - `/signup` → SignupPage  
  - `/` → HomePage (main screen with bottom nav)

---

## 🏠 Main Screen Structure

### **`lib/features/home/presentation/home_page.dart`** - Main Screen

This is the **main screen** you see after login. It has:

#### **Bottom Navigation Bar** (2 tabs):
1. **Home Tab** (index 0) - Shows feature cards grid
2. **Profile Tab** (index 1) - Shows ProfilePage

#### **Home Tab Content** - Feature Cards Grid:
Shows 4 feature cards:
- **Attendance** → Opens AttendancePage
- **Announcements** → Opens AnnouncementsTab
- **Teams** → Opens TeamsTab
- **Leave Apply** → Opens LeaveApplyTab

---

## 📍 Page Locations & Types

### **Type 1: Bottom Navigation Pages** (Always visible at bottom)

These are the main tabs in the bottom navigation bar:

| Page | Location | Description |
|------|---------|-------------|
| **Home Tab** | `lib/features/home/presentation/home_page.dart` | Shows feature cards grid |
| **Profile Tab** | `lib/features/profile/presentation/profile_page.dart` | User profile page |

**How to access**: Tap bottom navigation icons

---

### **Type 2: Feature Pages** (Opened from Home cards)

These pages open when you tap a feature card on the Home screen:

| Feature | Location | Description |
|---------|----------|-------------|
| **Attendance** | `lib/features/attendance/presentation/attendance_page.dart` | QR code scanner for attendance |
| **Announcements** | `lib/features/home/presentation/tabs/announcements_tab.dart` | View company announcements |
| **Teams** | `lib/features/home/presentation/tabs/teams_tab.dart` | View team members |
| **Leave Apply** | `lib/features/home/presentation/tabs/leave_apply_tab.dart` | Request leave |

**How to access**: Tap feature cards on Home screen

---

### **Type 3: Auth Pages** (Login/Signup)

| Page | Location | Description |
|------|---------|-------------|
| **Login** | `lib/features/auth/presentation/login_page.dart` | User login |
| **Signup** | `lib/features/auth/presentation/signup_page.dart` | User registration |

**How to access**: App starts here, or when logged out

---

### **Type 4: Other Feature Pages** (Not in home grid)

| Page | Location | Description |
|------|---------|-------------|
| **Chat** | `lib/features/chat/presentation/chat_page.dart` | Chat messages |
| **Dashboard** | `lib/features/dashboard/presentation/dashboard_page.dart` | Project dashboard |
| **Support** | `lib/features/support/presentation/support_page.dart` | Support tickets |

**How to access**: Currently not linked in home grid (can be added later)

---

## 🗂️ Complete File Structure

```
lib/
│
├── main.dart                    ⭐ APP STARTS HERE
├── app.dart                     ⭐ App configuration (theme, router)
│
├── core/                        🔧 Core app setup
│   ├── routing/
│   │   └── app_router.dart      📍 Defines all routes (login, home, etc.)
│   ├── theme/
│   │   └── app_theme.dart       🎨 App colors and styling
│   ├── constants/
│   │   ├── brand_colors.dart    🎨 Brand colors
│   │   └── roles.dart           👥 User roles
│   └── config/
│       └── supabase_config.dart 🔌 Database connection
│
├── features/                    📱 All app features
│   │
│   ├── home/                    🏠 MAIN SCREEN (Bottom Nav)
│   │   └── presentation/
│   │       ├── home_page.dart   ⭐ Main screen with bottom nav
│   │       └── tabs/
│   │           ├── announcements_tab.dart
│   │           ├── teams_tab.dart
│   │           └── leave_apply_tab.dart
│   │
│   ├── profile/                 👤 PROFILE TAB (Bottom Nav)
│   │   └── presentation/
│   │       └── profile_page.dart
│   │
│   ├── auth/                    🔐 LOGIN/SIGNUP
│   │   ├── controllers/
│   │   │   └── auth_controller.dart
│   │   └── presentation/
│   │       ├── login_page.dart
│   │       └── signup_page.dart
│   │
│   ├── attendance/              ✅ ATTENDANCE FEATURE
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   └── presentation/
│   │       └── attendance_page.dart
│   │
│   ├── chat/                    💬 CHAT FEATURE
│   │   ├── controllers/
│   │   └── presentation/
│   │       └── chat_page.dart
│   │
│   ├── announcements/           📢 ANNOUNCEMENTS
│   │   ├── controllers/
│   │   └── presentation/
│   │       └── announcements_page.dart
│   │
│   ├── dashboard/               📊 DASHBOARD
│   │   ├── controllers/
│   │   └── presentation/
│   │       └── dashboard_page.dart
│   │
│   └── support/                 🎫 SUPPORT TICKETS
│       ├── controllers/
│       └── presentation/
│           └── support_page.dart
│
├── data/                        💾 Data layer
│   ├── models/                  📋 Data models
│   └── services/                🔌 API services
│
└── shared/                      🔄 Shared widgets
    └── widgets/
        └── empty_state.dart
```

---

## 🔄 Navigation Flow

```
App Start
   ↓
main.dart (Initialize)
   ↓
app.dart (Setup theme & router)
   ↓
app_router.dart (Check auth)
   ↓
┌─────────────────┬─────────────────┐
│  Not Logged In  │   Logged In     │
│       ↓         │       ↓         │
│  LoginPage      │   HomePage      │
│       ↓         │       ↓         │
│  SignupPage     │  ┌──────────┐   │
│                 │  │ Home Tab │   │
│                 │  │ (Grid)   │   │
│                 │  └────┬─────┘   │
│                 │       │         │
│                 │  ┌────┴─────┐   │
│                 │  │ Profile  │   │
│                 │  │   Tab    │   │
│                 │  └──────────┘   │
│                 │                 │
│                 │  Feature Cards: │
│                 │  • Attendance   │
│                 │  • Announcements│
│                 │  • Teams        │
│                 │  • Leave Apply  │
└─────────────────┴─────────────────┘
```

---

## 🎯 Key Concepts

### **Bottom Navigation**
- **Location**: `home_page.dart` (line 78-94)
- **Tabs**: Home (index 0) and Profile (index 1)
- **How it works**: Tapping bottom icons switches between tabs

### **Feature Cards**
- **Location**: `home_page.dart` (line 22-59)
- **How it works**: Each card opens a different page when tapped
- **Navigation**: Uses `Navigator.push()` to open pages

### **Routes**
- **Location**: `app_router.dart`
- **How it works**: Defines URL paths (`/login`, `/`, etc.)
- **Auth Guard**: Redirects to login if not authenticated

---

## 📝 Quick Reference

### **To add a new page:**
1. Create file in `lib/features/[feature_name]/presentation/[page_name].dart`
2. Add route in `lib/core/routing/app_router.dart`
3. (Optional) Add card in `home_page.dart` to access it

### **To modify bottom navigation:**
- Edit `lib/features/home/presentation/home_page.dart` (line 78-94)

### **To add a feature card:**
- Edit `lib/features/home/presentation/home_page.dart` (line 22-59)

### **To change app theme:**
- Edit `lib/core/theme/app_theme.dart`

### **To change routes:**
- Edit `lib/core/routing/app_router.dart`

---

## 🎨 Visual Structure

```
┌─────────────────────────────────────┐
│         App Bar (if any)            │
├─────────────────────────────────────┤
│                                     │
│    Welcome, sandesh 👋              │
│    Pick a workspace feature...      │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │Attendance│  │Announce- │        │
│  │          │  │  ments   │        │
│  └──────────┘  └──────────┘        │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │  Teams   │  │Leave Apply│        │
│  │          │  │          │        │
│  └──────────┘  └──────────┘        │
│                                     │
├─────────────────────────────────────┤
│  🏠 Home    │    👤 Profile        │ ← Bottom Navigation
└─────────────────────────────────────┘
```

---

## ✅ Summary

- **Entry Point**: `main.dart` → `app.dart` → `app_router.dart`
- **Main Screen**: `home_page.dart` (has bottom nav)
- **Bottom Nav Pages**: Home Tab & Profile Tab
- **Feature Pages**: Opened from feature cards on Home screen
- **Auth Pages**: Login & Signup (shown when not logged in)

**Everything is organized by feature in `lib/features/` folder!**

