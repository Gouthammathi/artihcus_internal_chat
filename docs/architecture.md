# Architecture Overview

## Objectives

- Deliver a secure, brand-aligned mobile experience for Artihcus employees featuring chat, announcements, project dashboards, and support workflows.
- Support email/password authentication against the corporate employee master data, with role-based capabilities (employee, lead, manager, admin).
- Establish a modular foundation that can plug into future backend services without major refactors.

## High-Level Diagram

```
┌────────────────────┐
│      Presentation   │
│ ────────────────── │
│ Auth UI            │
│ Chat UI            │
│ Announcements UI   │
│ Dashboard UI       │
│ Support UI         │
└─────────┬──────────┘
          │ Riverpod Controllers
┌─────────▼──────────┐
│   Application Core  │
│ ────────────────── │
│ Routing (GoRouter) │
│ Theme + Branding   │
│ Shared Widgets     │
└─────────┬──────────┘
          │ Service Interfaces
┌─────────▼──────────┐
│      Data Layer     │
│ ────────────────── │
│ Auth Service       │
│ Chat Service       │
│ Announcement Svc   │
│ Project Service    │
│ Support Svc        │
└─────────┬──────────┘
          │ Mock Adapters (replaceable)
┌─────────▼──────────┐
│   Mock Data Store   │
│ ────────────────── │
│ In-memory employee │
│ lists, messages,   │
│ projects, tickets  │
└────────────────────┘
```

## Presentation Layer

- **Routing**: `GoRouter` orchestrates authentication flow and a `StatefulShellRoute` for bottom navigation (`chat`, `announcements`, `dashboard`, `support`).
- **State Management**: Feature pages use Riverpod to consume controller state, enabling testability and easy swapping of data sources.
- **Branding**: `AppTheme`, `BrandColors`, and `BrandLogo` apply Artihcus identity in line with the public site palette and typography.[^1]

## State Controllers

- `AuthController` wraps `AuthService`, exposing `AsyncValue<Employee?>` for reactive auth-aware routing.
- Each feature (chat, announcements, dashboard, support) has a dedicated controller subscribing to service streams and exposing helper methods (send message, publish announcement, create ticket, etc.).
- Controllers are the abstraction boundary between UI and services, ensuring minimal coupling.

## Data Layer

- **Service Interfaces**: Define the contract for authentication, chat, announcements, projects, and support. These interfaces simplify swapping the mock implementations with REST/GraphQL/Firebase backends.
- **Mock Services**: Provide deterministic demo data using in-memory stores (`mock_data.dart`) and broadcast controllers. They simulate latency and read/write operations for rapid prototyping.
- **Models**: Immutable value objects with `Equatable` to support deep comparisons and serialization (`toJson`/`fromJson`) ready for API integration.

## Authentication

- Email/password login uses the mock employee directory (`mockEmployees` and `mockCredentials`). Replace `MockAuthService` with a production adapter that queries the secure employee database and enforces password policies, MFA, or SSO.
- `AuthController` listens to the authentication stream, enabling real-time updates across the app (logout, role changes, etc.).

## Role-Based Access

- `EmployeeRole` enum centralizes permissions (`canBroadcastAnnouncements`, `canManageProjects`, `canManageSupportTickets`). Controllers reference these helpers to guard privileged actions.
- Future enhancements can extend this enum or move to a policy-based access layer.

## Extensibility Roadmap

1. **API Integration**: Replace mock services with network adapters (REST, gRPC, or SAP-centric APIs). Retrofit to Riverpod providers will keep UI untouched.
2. **Real-Time Messaging**: Introduce WebSocket or Firebase adapters for live chat, acknowledgements, and ticket updates.
3. **Secure Storage**: Persist auth tokens and offline cache using `flutter_secure_storage` and `hive`/`sqflite`.
4. **Notifications**: Hook into FCM or SAP Event Mesh for push notifications on announcements and ticket status changes.
5. **Analytics & Telemetry**: Instrument user actions to monitor engagement and SLA adherence.
6. **Branding Assets**: Replace placeholder logo with official high-resolution asset and load custom fonts when licensing permits.

## Testing Strategy

- Unit test controllers and services with mock dependencies.
- Widget tests for login and navigation flows.
- Golden tests to validate branding adherence.
- Integration tests once backend APIs are available.

[^1]: Brand reference: [Artihcus website](https://artihcus.com/)



