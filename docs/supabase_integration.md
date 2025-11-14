# Supabase Integration Documentation

## Overview

The Artihcus Internal Chat app is now fully integrated with Supabase, providing:

- ✅ **Real-time database** with PostgreSQL
- ✅ **Authentication** with email/password
- ✅ **Row Level Security (RLS)** for fine-grained access control
- ✅ **Realtime subscriptions** for live updates
- ✅ **Automatic schema management**

## Architecture

### Service Layer

All data access goes through service interfaces that abstract the backend:

```
Presentation (UI)
    ↓
Controllers (Riverpod StateNotifiers)
    ↓
Service Interfaces (Abstract Classes)
    ↓
Supabase Services (Implementation)
    ↓
Supabase Client (Backend)
```

### Service Implementations

| Feature | Service | Location |
|---------|---------|----------|
| Authentication | `SupabaseAuthService` | `lib/data/services/supabase/supabase_auth_service.dart` |
| Chat | `SupabaseChatService` | `lib/data/services/supabase/supabase_chat_service.dart` |
| Announcements | `SupabaseAnnouncementService` | `lib/data/services/supabase/supabase_announcement_service.dart` |
| Projects | `SupabaseProjectService` | `lib/data/services/supabase/supabase_project_service.dart` |
| Support Tickets | `SupabaseSupportTicketService` | `lib/data/services/supabase/supabase_support_ticket_service.dart` |

## Database Schema

### Tables

#### employees
Stores employee profiles, linked to Supabase Auth users.

```sql
- id: UUID (FK to auth.users)
- first_name: TEXT
- last_name: TEXT
- email: TEXT (unique)
- role: employee_role ENUM
- department: TEXT (nullable)
- avatar_url: TEXT (nullable)
- created_at, updated_at: TIMESTAMPTZ
```

#### chat_channels
Chat channels for organizing conversations.

```sql
- id: UUID (PK)
- name: TEXT (unique)
- description: TEXT
- created_at, updated_at: TIMESTAMPTZ
```

#### messages
Chat messages within channels.

```sql
- id: UUID (PK)
- channel_id: UUID (FK to chat_channels)
- sender_id: UUID (FK to employees)
- content: TEXT
- is_pinned: BOOLEAN
- created_at, updated_at: TIMESTAMPTZ
```

#### message_reads
Tracks which users have read which messages.

```sql
- id: UUID (PK)
- message_id: UUID (FK to messages)
- user_id: UUID (FK to employees)
- read_at: TIMESTAMPTZ
- UNIQUE(message_id, user_id)
```

#### announcements
Company-wide announcements with role targeting.

```sql
- id: UUID (PK)
- title: TEXT
- body: TEXT
- priority: announcement_priority ENUM
- published_by: UUID (FK to employees)
- target_roles: employee_role[] (array)
- created_at, updated_at: TIMESTAMPTZ
```

#### announcement_acknowledgements
Tracks which users have acknowledged announcements.

```sql
- id: UUID (PK)
- announcement_id: UUID (FK to announcements)
- user_id: UUID (FK to employees)
- acknowledged_at: TIMESTAMPTZ
- UNIQUE(announcement_id, user_id)
```

#### projects
Project management and tracking.

```sql
- id: UUID (PK)
- name: TEXT
- description: TEXT
- status: project_status ENUM
- owner_id: UUID (FK to employees)
- progress: DECIMAL (0-100)
- due_date: TIMESTAMPTZ (nullable)
- milestones: TEXT[] (array)
- created_at, updated_at: TIMESTAMPTZ
```

#### project_members
Many-to-many relationship for project team members.

```sql
- id: UUID (PK)
- project_id: UUID (FK to projects)
- employee_id: UUID (FK to employees)
- joined_at: TIMESTAMPTZ
- UNIQUE(project_id, employee_id)
```

#### support_tickets
Support ticket tracking system.

```sql
- id: TEXT (PK, format: SUP-YYYY-NNN)
- subject: TEXT
- description: TEXT
- status: ticket_status ENUM
- priority: ticket_priority ENUM
- created_by: UUID (FK to employees)
- assigned_to: UUID (FK to employees, nullable)
- tags: TEXT[] (array)
- created_at, updated_at: TIMESTAMPTZ
```

### Enums

```sql
employee_role: 'employee', 'lead', 'manager', 'admin'
announcement_priority: 'low', 'normal', 'high', 'critical'
project_status: 'onTrack', 'atRisk', 'blocked', 'completed'
ticket_status: 'open', 'inProgress', 'resolved', 'closed'
ticket_priority: 'low', 'normal', 'high', 'urgent'
```

## Row Level Security (RLS)

All tables have RLS enabled with policies based on user roles and ownership.

### Key Policies

- **Employees**: All authenticated users can view all employees, users can update their own profile
- **Chat**: All authenticated users can view and send messages
- **Announcements**: Leads, managers, and admins can publish; all can view
- **Projects**: Managers and admins can create; owners and admins can update
- **Support Tickets**: All can create and view; creators, assignees, and managers can update

## Realtime Subscriptions

The app subscribes to changes in:

- `messages` table → Real-time chat updates
- `announcements` table → Live announcement notifications
- `projects` table → Project status updates
- `support_tickets` table → Ticket status changes

### How It Works

Each service uses Supabase Realtime channels:

```dart
_realtimeChannel = _supabase
    .channel('messages_channel')
    .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        _refreshMessages();
      },
    )
    .subscribe();
```

## Authentication Flow

1. User enters email/password on login screen
2. `SupabaseAuthService.signIn()` calls `supabase.auth.signInWithPassword()`
3. On success, Supabase creates a session
4. Service fetches employee profile from `employees` table
5. `AuthController` emits the employee to the app
6. `AppRouter` redirects to home screen

### Session Management

- Sessions are automatically persisted by Supabase
- On app restart, `SupabaseAuthService` checks for existing session
- Session expiry is handled automatically with refresh tokens

## Error Handling

All service methods wrap Supabase calls in try-catch blocks:

```dart
try {
  await _supabase.from('table').insert(data);
} catch (e) {
  throw Exception('Failed to perform operation: ${e.toString()}');
}
```

Controllers catch these exceptions and update state:

```dart
try {
  await _service.someMethod();
} catch (error, stackTrace) {
  state = AsyncValue.error(error, stackTrace);
}
```

## Testing

### Local Development

Use the Supabase local development setup:

```bash
npx supabase init
npx supabase start
```

Update `.env` with local Supabase URL:

```env
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-local-anon-key
```

### Integration Testing

Create a separate Supabase project for testing:

- Use environment-specific `.env` files
- Reset database between test runs
- Use predictable test data

## Performance Considerations

### Indexes

All foreign keys and frequently queried columns have indexes:

```sql
CREATE INDEX idx_messages_channel_id ON messages(channel_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);
```

### Pagination

For large datasets, implement pagination:

```dart
final response = await _supabase
    .from('messages')
    .select()
    .eq('channel_id', channelId)
    .order('created_at', ascending: false)
    .range(start, end);
```

### Caching

Consider implementing local caching with:
- `hive` or `sqflite` for offline data
- `cached_network_image` for avatars
- TTL-based cache invalidation

## Security Best Practices

1. **Never use service_role key in client apps** - Only use anon/public key
2. **Validate all inputs** - Both client-side and in RLS policies
3. **Use parameterized queries** - Supabase handles this automatically
4. **Review RLS policies regularly** - Ensure they match business requirements
5. **Enable audit logging** - Track who changed what and when
6. **Rotate keys periodically** - Especially in production

## Troubleshooting

### Common Issues

**Issue**: "Failed to fetch employee profile"
- **Solution**: Check that user exists in both `auth.users` and `employees` tables

**Issue**: "Row Level Security policy violation"
- **Solution**: Verify the current user has permission to access the data

**Issue**: "Realtime not working"
- **Solution**: Enable replication for the table in Supabase dashboard

**Issue**: "CORS errors in web"
- **Solution**: Add your domain to allowed origins in Supabase settings

## Future Enhancements

- [ ] Add offline-first capabilities with local database sync
- [ ] Implement optimistic updates for better UX
- [ ] Add file storage for avatars and attachments
- [ ] Set up Edge Functions for complex business logic
- [ ] Add database migrations for schema versioning
- [ ] Implement analytics and monitoring
- [ ] Add automated backup and restore procedures

## Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Realtime](https://supabase.com/docs/guides/realtime)

