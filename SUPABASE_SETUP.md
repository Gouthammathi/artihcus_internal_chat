# Supabase Setup Guide for Artihcus Internal Chat

This guide will walk you through setting up Supabase as the backend for the Artihcus Internal Chat application.

## Prerequisites

- Flutter 3.24 or later installed
- A Supabase account (sign up at https://supabase.com)
- Git installed

## Step 1: Create a Supabase Project

1. Go to https://supabase.com and sign in (or create an account)
2. Click "New Project"
3. Fill in the details:
   - **Name**: `artihcus-internal-chat`
   - **Database Password**: Choose a strong password (save this!)
   - **Region**: Choose the closest region to your users
4. Click "Create new project"
5. Wait for the project to be provisioned (usually takes 1-2 minutes)

## Step 2: Set Up the Database Schema

1. In your Supabase project dashboard, click on the **SQL Editor** tab in the left sidebar
2. Click "New query"
3. Copy the entire contents of `supabase_schema.sql` from your project root
4. Paste it into the SQL editor
5. Click **Run** or press `Ctrl/Cmd + Enter`
6. You should see "Success. No rows returned" message

This will create all the necessary tables, indexes, and Row Level Security policies.

## Step 3: Configure Environment Variables

1. In your Supabase project dashboard, click on the **Settings** icon in the left sidebar (gear icon)
2. Click on **API** under Project Settings
3. You'll see your **Project URL** and **API Keys**
4. Copy the **Project URL**
5. Copy the **anon public** key (NOT the service_role key)

Now create a `.env` file in your project root:

```bash
# .env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key-here
```

**Important**: Replace the values with your actual Supabase credentials!

## Step 4: Install Dependencies

Run the following command in your project directory:

```bash
flutter pub get
```

This will install all required dependencies including `supabase_flutter` and `flutter_dotenv`.

## Step 5: Create Test Users

Since you're using Supabase Auth, you need to create users through the Supabase dashboard:

### Option A: Using Supabase Dashboard (Recommended)

1. In your Supabase project, go to **Authentication** → **Users**
2. Click **Add user** → **Create new user**
3. Fill in:
   - **Email**: `ck.reddy@artihcus.com`
   - **Password**: `Welcome@2025`
   - **Auto Confirm User**: ✅ (checked)
   - **User Metadata**: Click "Add additional fields" and add:
     ```json
     {
       "first_name": "C.K",
       "last_name": "Reddy",
       "role": "admin"
     }
     ```
4. Click **Create user**
5. Repeat for other employees (refer to `lib/data/services/mock/mock_data.dart` for the complete list)

### Option B: Using SQL (Faster for Multiple Users)

1. Go to **SQL Editor** in Supabase
2. Run this SQL to create all test users at once:

```sql
-- Insert test users with auth
-- Note: You'll need to set passwords through the Supabase Auth UI or via API

-- CK Reddy (Admin)
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    recovery_token
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'ck.reddy@artihcus.com',
    crypt('Welcome@2025', gen_salt('bf')),
    now(),
    '{"first_name":"C.K","last_name":"Reddy","role":"admin"}',
    now(),
    now(),
    '',
    ''
);

-- Repeat similar INSERT statements for other users...
```

## Step 6: Set Up Realtime (Optional but Recommended)

For real-time chat and updates:

1. Go to **Database** → **Replication** in your Supabase dashboard
2. Enable replication for these tables:
   - ✅ messages
   - ✅ announcements
   - ✅ projects
   - ✅ support_tickets
3. Click **Save**

## Step 7: Configure Storage (Optional - for future file uploads)

If you plan to add file attachments or avatar uploads:

1. Go to **Storage** in your Supabase dashboard
2. Click **Create a new bucket**
3. Create buckets as needed:
   - `avatars` (for profile pictures)
   - `attachments` (for chat/ticket attachments)
4. Set appropriate policies for each bucket

## Step 8: Test the Application

1. Run the Flutter app:

```bash
flutter run
```

2. Try logging in with one of the test accounts:
   - Email: `ck.reddy@artihcus.com`
   - Password: `Welcome@2025`

3. If successful, you should see the home screen!

## Troubleshooting

### Error: "Invalid API key"
- Double-check that you copied the **anon public** key, not the service_role key
- Make sure there are no extra spaces in your `.env` file

### Error: "Failed to fetch employee profile"
- Verify the database schema was created correctly
- Check that the user exists in both `auth.users` and `employees` tables
- Make sure Row Level Security policies are set up correctly

### Error: "Could not load .env file"
- Ensure `.env` file is in the project root (not in a subdirectory)
- Run `flutter clean` and `flutter pub get` again

### Messages/Data not appearing in real-time
- Check that Realtime is enabled for the relevant tables
- Verify your Row Level Security policies allow reading the data

## Seed Data (Optional)

To populate your database with test data for development:

1. Create some chat channels (already done by schema)
2. Send some test messages
3. Create test announcements
4. Add test projects
5. Create test support tickets

You can do this through the app UI once logged in, or through SQL in the Supabase SQL Editor.

## Production Considerations

Before deploying to production:

1. **Change default passwords**: Update all test user passwords
2. **Review RLS policies**: Ensure they match your security requirements
3. **Enable MFA**: Consider enabling multi-factor authentication
4. **Set up backups**: Configure automatic database backups in Supabase
5. **Environment variables**: Use different Supabase projects for dev/staging/production
6. **Rate limiting**: Configure rate limits in Supabase to prevent abuse
7. **Monitoring**: Set up alerts for database performance and errors

## Next Steps

- [ ] Customize Row Level Security policies for your specific needs
- [ ] Add email templates for password resets and notifications
- [ ] Set up Supabase Edge Functions for custom business logic
- [ ] Configure webhooks for external integrations
- [ ] Add analytics and monitoring

## Support

For issues with:
- **Supabase**: Check https://supabase.com/docs or https://github.com/supabase/supabase/discussions
- **This app**: Contact your development team

## Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Realtime Guide](https://supabase.com/docs/guides/realtime)

