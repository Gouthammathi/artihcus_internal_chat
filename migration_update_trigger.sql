-- Migration: Update handle_new_user trigger function
-- Run this in Supabase SQL Editor to fix the signup 500 error
-- This only updates the trigger function, it doesn't recreate tables

-- Drop the existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Function to automatically create user profile on signup
-- Improved version with better error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_role TEXT;
    user_first_name TEXT;
    user_last_name TEXT;
    user_department TEXT;
BEGIN
    -- Extract metadata with defaults
    user_first_name := COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'first_name'), ''), 'New');
    user_last_name := COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'last_name'), ''), 'User');
    user_role := NULLIF(TRIM(NEW.raw_user_meta_data->>'role'), '');
    user_department := NULLIF(TRIM(NEW.raw_user_meta_data->>'department'), '');
    
    -- First, insert into users table (with conflict handling)
    INSERT INTO public.users (id, email, first_name, last_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.email, ''),
        user_first_name,
        user_last_name
    )
    ON CONFLICT (id) DO UPDATE SET
        email = COALESCE(EXCLUDED.email, users.email),
        first_name = COALESCE(EXCLUDED.first_name, users.first_name),
        last_name = COALESCE(EXCLUDED.last_name, users.last_name),
        updated_at = NOW();
    
    -- If role is specified in metadata, also create employee record
    -- Default to 'employee' if role is not provided or invalid
    IF user_role IS NULL OR user_role NOT IN ('employee', 'lead', 'manager', 'admin') THEN
        user_role := 'employee';
    END IF;
    
    -- Always create employee record (default role if not specified)
    INSERT INTO public.employees (id, role, department)
    VALUES (
        NEW.id,
        user_role::employee_role,
        user_department
    )
    ON CONFLICT (id) DO UPDATE SET
        role = COALESCE(EXCLUDED.role, employees.role),
        department = COALESCE(EXCLUDED.department, employees.department),
        updated_at = NOW();
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the auth user creation
        -- The Flutter app will handle creating the profile manually if needed
        RAISE WARNING 'Error in handle_new_user trigger: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Fix RLS policies to allow users to create their own profile (for manual fallback)
-- Drop existing insert policies
DROP POLICY IF EXISTS "System can insert users via trigger" ON users;
DROP POLICY IF EXISTS "System can insert employees via trigger" ON employees;

-- Allow users to insert their own profile (for manual creation fallback)
CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow users to insert their own employee record (for manual creation fallback)
CREATE POLICY "Users can insert their own employee record" ON employees
    FOR INSERT WITH CHECK (auth.uid() = id);

-- The trigger function runs with SECURITY DEFINER, so it can still insert
-- even without explicit policies, but having these policies helps with manual inserts
