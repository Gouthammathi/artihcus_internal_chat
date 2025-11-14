-- Migration: Fix RLS policies to allow users to create their own profile
-- Run this in Supabase SQL Editor to fix the 403 Forbidden error during login

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

