# Supabase Integration Setup Checklist ✅

Use this checklist to ensure you've completed all steps for the Supabase integration.

## 📦 Installation & Dependencies

- [ ] Run `flutter pub get` to install dependencies
- [ ] Verify `supabase_flutter` and `flutter_dotenv` are installed
- [ ] Check that Flutter SDK version is 3.24 or later

## 🔧 Supabase Project Setup

- [ ] Create Supabase account at https://supabase.com
- [ ] Create new project named `artihcus-internal-chat`
- [ ] Wait for project provisioning to complete
- [ ] Note down the database password

## 🗄️ Database Configuration

- [ ] Open Supabase SQL Editor
- [ ] Copy contents of `supabase_schema.sql`
- [ ] Run the SQL script
- [ ] Verify "Success. No rows returned" message
- [ ] Check tables were created (Database → Table Editor)
  - [ ] employees
  - [ ] chat_channels
  - [ ] messages
  - [ ] message_reads
  - [ ] announcements
  - [ ] announcement_acknowledgements
  - [ ] projects
  - [ ] project_members
  - [ ] support_tickets

## 🔑 API Credentials

- [ ] Go to Settings → API in Supabase dashboard
- [ ] Copy **Project URL**
- [ ] Copy **anon public** key (NOT service_role)
- [ ] Create `.env` file in project root
- [ ] Add `SUPABASE_URL=your_url`
- [ ] Add `SUPABASE_ANON_KEY=your_key`
- [ ] Verify no extra spaces or line breaks

## 👥 User Creation

Create at least one test user:

- [ ] Go to Authentication → Users in Supabase
- [ ] Click "Add user" → "Create new user"
- [ ] Set email: `ck.reddy@artihcus.com`
- [ ] Set password: `Welcome@2025`
- [ ] Check "Auto Confirm User" ✅
- [ ] Add user metadata:
  ```json
  {
    "first_name": "C.K",
    "last_name": "Reddy",
    "role": "admin"
  }
  ```
- [ ] Click "Create user"
- [ ] Verify user appears in employees table (Database → Table Editor)

### Optional: Create Additional Test Users

- [ ] Manager: `nara.reddy@artihcus.com` (role: manager)
- [ ] Lead: `hari.andluru@artihcus.com` (role: lead)
- [ ] Employee: `aaradhya.patel@artihcus.com` (role: employee)

## ⚡ Realtime Configuration

- [ ] Go to Database → Replication
- [ ] Enable replication for:
  - [ ] messages
  - [ ] announcements
  - [ ] projects
  - [ ] support_tickets
- [ ] Click "Save"

## 🎨 Assets & Branding

- [ ] Add `assets/images/logo.png` (or use existing)
- [ ] Verify assets are declared in `pubspec.yaml`

## 🧪 Testing

### Build & Run
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Run `flutter run`
- [ ] App starts without errors
- [ ] No console errors

### Authentication Test
- [ ] Login screen appears
- [ ] Enter test credentials
- [ ] Click "Sign In"
- [ ] Successfully redirects to home screen
- [ ] User name appears in profile

### Feature Tests

**Chat Tab:**
- [ ] Navigate to Chat tab
- [ ] See channel list (general, support, announcements)
- [ ] Select a channel
- [ ] Send a test message
- [ ] Message appears in the chat

**Announcements Tab:**
- [ ] Navigate to Announcements tab
- [ ] See empty state or existing announcements
- [ ] (If admin) Click "+" button
- [ ] (If admin) Create announcement
- [ ] Announcement appears in list

**Dashboard Tab:**
- [ ] Navigate to Dashboard tab
- [ ] See empty state or project cards
- [ ] (If manager/admin) Create project button visible

**Support Tab:**
- [ ] Navigate to Support tab
- [ ] See empty state or tickets
- [ ] Click "+" to create ticket
- [ ] Fill in ticket details
- [ ] Submit ticket
- [ ] Ticket appears in list

**Profile:**
- [ ] Click profile icon/tab
- [ ] See user information
- [ ] Click "Sign Out"
- [ ] Redirects to login screen

### Real-time Test (Optional but Recommended)
- [ ] Open app on two devices/emulators
- [ ] Log in with different users on each
- [ ] Send message from Device 1
- [ ] Verify message appears on Device 2 instantly
- [ ] Create announcement from Device 1 (as admin)
- [ ] Verify announcement appears on Device 2

## 📊 Supabase Dashboard Verification

- [ ] Database → Table Editor → employees: See user records
- [ ] Database → Table Editor → chat_channels: See 3 channels
- [ ] Database → Table Editor → messages: See test messages (if sent)
- [ ] Authentication → Users: See created users
- [ ] Database → Replication: Realtime enabled for key tables

## 🐛 Troubleshooting Checks

If something isn't working, verify:

- [ ] `.env` file exists in project root (same level as `pubspec.yaml`)
- [ ] No typos in environment variable names
- [ ] Used **anon public** key, not service_role key
- [ ] Database schema ran without errors
- [ ] User has metadata (first_name, last_name, role)
- [ ] User email was auto-confirmed
- [ ] Internet connection is active
- [ ] Supabase project is not paused (free tier auto-pauses after 1 week inactivity)

## 📚 Documentation Review

Have you read:

- [ ] `README.md` - Project overview
- [ ] `QUICK_START.md` - Quick setup guide
- [ ] `SUPABASE_SETUP.md` - Detailed setup instructions
- [ ] `INTEGRATION_SUMMARY.md` - What was changed
- [ ] `docs/supabase_integration.md` - Technical details

## 🚀 Production Readiness (Before Deployment)

- [ ] Create separate production Supabase project
- [ ] Use production environment variables
- [ ] Change all default passwords
- [ ] Review Row Level Security policies
- [ ] Set up database backups
- [ ] Configure custom domain (optional)
- [ ] Set up monitoring and alerts
- [ ] Test on physical devices (not just emulators)
- [ ] Test on both iOS and Android
- [ ] Test on slow network connections
- [ ] Perform security audit
- [ ] Load test with multiple concurrent users

## 💡 Optional Enhancements

- [ ] Set up Supabase Storage for file uploads
- [ ] Configure email templates for password reset
- [ ] Add custom email SMTP server
- [ ] Set up Supabase Edge Functions
- [ ] Configure webhooks
- [ ] Add custom database functions
- [ ] Set up analytics
- [ ] Enable 2FA for admins

## ✅ Final Verification

Everything is working if:

- [x] App builds and runs without errors
- [x] Can login with test credentials
- [x] Can navigate to all tabs
- [x] Can send a chat message
- [x] Profile shows correct user info
- [x] Can logout successfully
- [x] No errors in console/logs

---

## 🎉 Congratulations!

If all items are checked, your Supabase integration is complete and ready for use!

### Next Steps:
1. Create more test users with different roles
2. Populate test data for realistic testing
3. Customize for your organization's needs
4. Deploy to production when ready

---

**Need Help?**
- Check `SUPABASE_SETUP.md` for troubleshooting
- Review `docs/supabase_integration.md` for technical details
- Visit Supabase documentation: https://supabase.com/docs
- Check Supabase community: https://github.com/supabase/supabase/discussions

Happy coding! 🚀

