# Quick Start Guide - Supabase Integration

Get up and running with Artihcus Internal Chat in 10 minutes!

## 🚀 Fast Setup (TL;DR)

```bash
# 1. Clone and install dependencies
flutter pub get

# 2. Create Supabase project at https://supabase.com

# 3. Run SQL schema
# Copy contents of supabase_schema.sql to Supabase SQL Editor and run it

# 4. Create .env file
echo "SUPABASE_URL=https://xxxxx.supabase.co" > .env
echo "SUPABASE_ANON_KEY=your-anon-key" >> .env

# 5. Create a test user in Supabase Auth dashboard
# Email: ck.reddy@artihcus.com, Password: Welcome@2025
# User metadata: {"first_name":"C.K","last_name":"Reddy","role":"admin"}

# 6. Run the app
flutter run
```

## 📋 Step-by-Step Setup

### Step 1: Create Supabase Project (2 min)

1. Go to https://supabase.com
2. Sign in or create account
3. Click **"New Project"**
4. Fill in:
   - Name: `artihcus-internal-chat`
   - Password: (choose strong password)
   - Region: (closest to you)
5. Click **"Create new project"**
6. Wait ~1 minute for provisioning

### Step 2: Set Up Database (2 min)

1. In Supabase dashboard, go to **SQL Editor**
2. Click **"New query"**
3. Open `supabase_schema.sql` from project root
4. Copy entire contents and paste into SQL editor
5. Click **"Run"** (Ctrl/Cmd + Enter)
6. You should see "Success. No rows returned"

### Step 3: Get API Credentials (1 min)

1. In Supabase dashboard, click **Settings** (gear icon)
2. Click **API** in the menu
3. Copy two values:
   - **Project URL** (starts with https://)
   - **anon public** key (long string)

### Step 4: Configure App (1 min)

Create `.env` file in project root:

```env
SUPABASE_URL=paste_your_project_url_here
SUPABASE_ANON_KEY=paste_your_anon_key_here
```

Example:
```env
SUPABASE_URL=https://abcdefghijk.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprIiwicm9sZSI6ImFub24iLCJpYXQiOjE2MjYyNzM4NjcsImV4cCI6MTk0MTg0OTg2N30.abcdefghijk123456789
```

### Step 5: Create Test User (2 min)

1. In Supabase dashboard, go to **Authentication** → **Users**
2. Click **"Add user"** → **"Create new user"**
3. Fill in:
   - **Email**: `ck.reddy@artihcus.com`
   - **Password**: `Welcome@2025`
   - **Auto Confirm User**: ✅ Check this box!
4. Click **"Add additional fields"** and paste:
   ```json
   {
     "first_name": "C.K",
     "last_name": "Reddy",
     "role": "admin"
   }
   ```
5. Click **"Create user"**

### Step 6: Enable Realtime (1 min)

1. Go to **Database** → **Replication** in Supabase
2. Enable these tables:
   - ✅ messages
   - ✅ announcements
   - ✅ projects
   - ✅ support_tickets
3. Click **"Save"**

### Step 7: Run the App (1 min)

```bash
flutter pub get
flutter run
```

Login with:
- **Email**: `ck.reddy@artihcus.com`
- **Password**: `Welcome@2025`

## ✅ Verification Checklist

Make sure everything is working:

- [ ] App starts without errors
- [ ] Login screen appears
- [ ] Can log in with test credentials
- [ ] Home screen loads with bottom navigation
- [ ] Can navigate to Chat, Announcements, Dashboard, Support tabs
- [ ] Profile page shows user info

## 🐛 Troubleshooting

### "Could not load .env file"
**Fix**: Make sure `.env` is in the project root (same folder as `pubspec.yaml`)

### "Invalid API key"
**Fix**: 
1. Double-check you copied the **anon public** key (NOT service_role)
2. Make sure there are no spaces or line breaks in the key
3. Make sure the key is on the same line as `SUPABASE_ANON_KEY=`

### "Failed to fetch employee profile"
**Fix**: 
1. Make sure you ran the `supabase_schema.sql` successfully
2. Check that the user was created with user metadata (first_name, last_name, role)
3. Go to Supabase **Database** → **Table Editor** → **employees** and verify the user appears there

### "Can't sign in" or "Wrong password"
**Fix**:
1. In Supabase **Authentication** → **Users**, verify the user exists
2. Make sure you checked **"Auto Confirm User"** when creating the user
3. Try resetting the password in Supabase dashboard

### App crashes on startup
**Fix**:
1. Run `flutter clean`
2. Run `flutter pub get`
3. Make sure `.env` file exists and has both variables
4. Check terminal for specific error messages

## 📚 Next Steps

1. **Add more test users** - Create users with different roles (manager, lead, employee)
2. **Test features** - Try sending messages, creating announcements, etc.
3. **Read documentation** - Check `SUPABASE_SETUP.md` for detailed information
4. **Customize** - Modify for your organization's needs

## 🎯 Test the Features

### Test Chat
1. Navigate to **Chat** tab
2. Select **#general** channel
3. Type a message and send

### Test Announcements
1. Navigate to **Announcements** tab
2. As admin, tap the "+" button
3. Create a new announcement

### Test Dashboard
1. Navigate to **Dashboard** tab
2. View project cards

### Test Support
1. Navigate to **Support** tab
2. Create a new ticket

## 💡 Pro Tips

- **Multiple users**: Create several test users with different roles to test permissions
- **Realtime testing**: Open app on two devices/emulators simultaneously to see real-time updates
- **Database viewer**: Use Supabase Table Editor to see data as you create it
- **Logs**: Check Supabase **Logs** section to debug issues

## 📞 Need Help?

- Check [SUPABASE_SETUP.md](SUPABASE_SETUP.md) for detailed setup instructions
- Read [docs/supabase_integration.md](docs/supabase_integration.md) for technical details
- Review [Supabase Documentation](https://supabase.com/docs)

---

**Estimated total time**: ~10 minutes

Happy coding! 🚀

