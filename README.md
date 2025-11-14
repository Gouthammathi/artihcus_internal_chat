# Artihcus Internal Chat App

Artihcus Internal Chat is a Flutter application that enables secure real-time collaboration for all Artihcus employees. It delivers authenticated messaging, announcements, lightweight project oversight, and support ticket tracking in a single mobile-first experience aligned to Artihcus branding and operating needs.

## Key Features

- Email + password authentication against the employee directory with role-aware navigation.
- Real-time style chat threads with read indicators and persistent history.
- Broadcast announcements with priority, scheduling, and read receipts by role or team.
- Project dashboard cards highlighting status, milestones, and open actions.
- Support ticket intake, triage, and resolution workflows with assignments.
- Unified notification center and quick actions for high-signal events.

## Project Structure

```text
lib/
 ├─ core/                # Routing, theming, constants, shared widgets
 ├─ data/                # Models and service interfaces (mock + future adapters)
 ├─ features/            # Feature-specific presentation + controllers
 ├─ shared/              # Reusable UI components
 ├─ app.dart             # Root widget with router + theme
 └─ main.dart            # Application entry point
```

## Getting Started

### Prerequisites

1. Install Flutter 3.24 or later and enable required platforms (`flutter config --enable-<platform>-desktop` as needed).
2. Create a Supabase account at https://supabase.com (free tier available)

### Setup Instructions

1. **Set up Supabase backend**:
   - Follow the detailed instructions in [SUPABASE_SETUP.md](SUPABASE_SETUP.md)
   - Create a new Supabase project
   - Run the SQL schema from `supabase_schema.sql`
   - Get your project URL and anon key

2. **Configure environment variables**:
   - Create a `.env` file in the project root:
     ```env
     SUPABASE_URL=your_supabase_project_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     ```
   - Replace with your actual Supabase credentials

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Add branding assets**:
   - Add the official Artihcus logo as `assets/images/artihcus_logo.png` (PNG, ≥512px width with transparent background)

5. **Create test users**:
   - In Supabase dashboard, go to Authentication → Users
   - Create test users with the following credentials:
     - Email: `ck.reddy@artihcus.com`, Password: `Welcome@2025`, Role: `admin`
     - See `SUPABASE_SETUP.md` for complete list

6. **Run the app**:
   ```bash
   flutter run
   ```

### Login Credentials (Test Users)

After setting up users in Supabase, you can log in with:
- **Admin**: `ck.reddy@artihcus.com` / `Welcome@2025`
- **Manager**: `nara.reddy@artihcus.com` / `Welcome@2025`
- **Lead**: `hari.andluru@artihcus.com` / `Welcome@2025`
- **Employee**: `aaradhya.patel@artihcus.com` / `Welcome@2025`

## Branding

- Primary color: `#0B1F4B`
- Secondary color: `#F26A21`
- Accent color: `#27A8E0`
- Neutral background: `#F6F8FC`
- Primary typeface: Urbanist (fall back to `Roboto` until company font licensing is confirmed)
- Logo: supplied via `assets/images/artihcus_logo.png`

The color palette and branding cues were derived from the official Artihcus website and collateral.[^1]

## Authentication & Roles

- Supported roles: `employee`, `lead`, `manager`, `admin`.
- Authentication abstraction allows swapping the mock provider with REST, GraphQL, or Firebase adapters.
- Role-based visibility rules are centralized in `core/constants/roles.dart`.

## Roadmap

- [x] **Supabase Backend Integration** - Real-time database with PostgreSQL
- [x] **Real-time Updates** - Live chat and announcements via Supabase Realtime
- [x] **Row Level Security** - Fine-grained access control based on roles
- [ ] Offline caching and sync with local storage
- [ ] Push notifications via Firebase Cloud Messaging
- [ ] File attachments for chat and support tickets
- [ ] Implement detailed analytics dashboards per role
- [ ] Harden security with MFA and device management policies
- [ ] Add email notifications for important events

## Contributing

1. Create a feature branch.
2. Run `flutter analyze` and `flutter test`.
3. Open a pull request with screenshots or short clips for UI changes.

## License

This project is proprietary and intended for internal Artihcus use only.

[^1]: Brand reference: [Artihcus website](https://artihcus.com/)



