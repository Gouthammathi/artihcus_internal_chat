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

1. Install Flutter 3.24 or later and enable required platforms (`flutter config --enable-<platform>-desktop` as needed).
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Add the official Artihcus logo as `assets/images/artihcus_logo.png` (PNG, ≥512px width with transparent background).
4. Run the app on your preferred device:
   ```bash
   flutter run
   ```

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

- [ ] Replace mock services with secure backend integrations.
- [ ] Add WebSocket-powered live updates for chat & announcements.
- [ ] Introduce offline caching and retries.
- [ ] Implement detailed analytics dashboards per role.
- [ ] Harden security with MFA and device management policies.

## Contributing

1. Create a feature branch.
2. Run `flutter analyze` and `flutter test`.
3. Open a pull request with screenshots or short clips for UI changes.

## License

This project is proprietary and intended for internal Artihcus use only.

[^1]: Brand reference: [Artihcus website](https://artihcus.com/)



