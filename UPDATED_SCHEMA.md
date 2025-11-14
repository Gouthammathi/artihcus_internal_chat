# ✅ Updated Database Schema with Separate Users Table

## 🎯 New Structure

```
┌─────────────────┐
│   auth.users    │  ← Supabase Auth (managed)
│   (Auth data)   │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│      users      │  ← All signup users go here
│  (Profile data) │
└────────┬────────┘
         │
         ↓ (optional - only if role specified)
┌─────────────────┐
│    employees    │  ← Only employees with roles
│  (Employee data)│
└─────────────────┘
```

## 📊 Table Details

### 1. **users** Table (NEW!)
**All signup users stored here**

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | FK to auth.users (PK) |
| first_name | TEXT | User's first name |
| last_name | TEXT | User's last name |
| email | TEXT | User's email (unique) |
| avatar_url | TEXT | Profile picture URL (optional) |
| created_at | TIMESTAMPTZ | Signup timestamp |
| updated_at | TIMESTAMPTZ | Last update timestamp |

### 2. **employees** Table (UPDATED!)
**Only for actual employees with roles and departments**

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | FK to users (PK) |
| role | employee_role | Employee role (employee, lead, manager, admin) |
| department | TEXT | Department name (optional) |
| employee_number | TEXT | Unique employee ID (optional) |
| hire_date | TIMESTAMPTZ | Hire date (defaults to NOW) |
| created_at | TIMESTAMPTZ | Record creation timestamp |
| updated_at | TIMESTAMPTZ | Last update timestamp |

---

## 🔄 How It Works

### **Signup Flow:**

1. **User signs up** with email, password, first_name, last_name, role, department

2. **Supabase creates auth user** in `auth.users`

3. **Database trigger fires** (`handle_new_user()`):
   - ✅ Always creates record in `users` table
   - ✅ If `role` is provided → Also creates record in `employees` table
   - ❌ If `role` is NULL → Only `users` record created (regular user, not employee)

4. **App fetches profile**:
   - Queries `users` table
   - LEFT JOINs with `employees` table
   - Returns combined data

---

## 📝 Examples

### Example 1: Employee Signup (has role)
```sql
-- User metadata includes role
{
  "first_name": "John",
  "last_name": "Doe", 
  "role": "employee",
  "department": "Engineering"
}

-- Result:
✅ Record created in auth.users
✅ Record created in users table
✅ Record created in employees table (because role specified)
```

### Example 2: Regular User Signup (no role)
```sql
-- User metadata without role
{
  "first_name": "Jane",
  "last_name": "Smith"
}

-- Result:
✅ Record created in auth.users
✅ Record created in users table
❌ No record in employees table (no role specified)
```

---

## 🔍 Queries

### Get User Profile (App does this automatically)
```sql
SELECT 
  u.*,
  e.role,
  e.department,
  e.employee_number,
  e.hire_date
FROM users u
LEFT JOIN employees e ON u.id = e.id
WHERE u.id = 'user-id-here';
```

### Get All Users
```sql
SELECT * FROM users;
```

### Get All Employees Only
```sql
SELECT 
  u.first_name,
  u.last_name,
  u.email,
  e.role,
  e.department
FROM users u
INNER JOIN employees e ON u.id = e.id;
```

### Check if User is Employee
```sql
SELECT EXISTS(
  SELECT 1 FROM employees WHERE id = 'user-id-here'
) as is_employee;
```

---

## ✅ Benefits of This Structure

### 1. **Flexibility**
- ✅ Not all users need to be employees
- ✅ Can have "guest" users, "customers", etc.
- ✅ Easy to add more user types later

### 2. **Clean Separation**
- ✅ User data (name, email) separate from employee data (role, department)
- ✅ Can delete employee record without losing user account
- ✅ Can promote regular user to employee later

### 3. **Scalability**
- ✅ Can add more tables: `customers`, `vendors`, `partners`
- ✅ All link to `users` table
- ✅ Maintains referential integrity

---

## 🔧 Code Changes Made

### 1. **Updated `supabase_schema.sql`**
- ✅ Added `users` table
- ✅ Modified `employees` table to reference `users`
- ✅ Updated trigger to create both records
- ✅ Added RLS policies for both tables
- ✅ Added indexes and constraints

### 2. **Updated `supabase_auth_service.dart`**
- ✅ Modified `_fetchEmployeeProfile()` to query users with LEFT JOIN
- ✅ Handles cases where employee record doesn't exist
- ✅ Increased delay to 800ms for trigger completion

### 3. **Schema is backward compatible**
- ✅ Existing Employee model still works
- ✅ No changes needed in other parts of app
- ✅ Signup flow unchanged from user perspective

---

## 🚀 Next Steps

### 1. **Run the Updated Schema**
```bash
# In Supabase SQL Editor, run: supabase_schema.sql
```

### 2. **Test Signup**
```bash
# Signup with role (becomes employee)
First Name: John
Last Name: Doe
Email: john@artihcus.com
Role: Employee
Department: Engineering

# Check:
✅ Record in users table
✅ Record in employees table
```

### 3. **Verify in Supabase**
```bash
# Go to Database → Table Editor
1. Check "users" table - should have the user
2. Check "employees" table - should have the employee record
3. Both should have same ID
```

---

## 📋 Migration Notes

### If you already have data:
```sql
-- This is handled automatically by the schema
-- The trigger creates records in both tables for new signups
```

### To convert existing users to new structure:
```sql
-- If you have existing data in old employees table, run:
-- (Only if needed - new setup handles this automatically)
```

---

## 🎯 Current Status

✅ **Schema updated** - Both tables created
✅ **Trigger updated** - Creates records in both tables
✅ **Code updated** - Service queries both tables
✅ **RLS policies** - Security enabled for both
✅ **Ready to test** - Run the schema and test signup!

---

## 📞 Testing

1. **Run the schema** in Supabase SQL Editor
2. **Restart your app**
3. **Try signup** with all fields
4. **Check Supabase**:
   - Authentication → Users (auth user created)
   - Database → users table (user record created)
   - Database → employees table (employee record created)

---

**Now run the updated `supabase_schema.sql` in your Supabase dashboard!** 🚀

