-- Artihcus Internal Chat - Supabase Database Schema
-- Run this SQL in your Supabase SQL Editor

-- Create enum types (drop first if they exist to allow re-running this script)
DROP TYPE IF EXISTS employee_role CASCADE;
DROP TYPE IF EXISTS announcement_priority CASCADE;
DROP TYPE IF EXISTS project_status CASCADE;
DROP TYPE IF EXISTS ticket_status CASCADE;
DROP TYPE IF EXISTS ticket_priority CASCADE;

CREATE TYPE employee_role AS ENUM ('employee', 'lead', 'manager', 'admin');
CREATE TYPE announcement_priority AS ENUM ('low', 'normal', 'high', 'critical');
CREATE TYPE project_status AS ENUM ('onTrack', 'atRisk', 'blocked', 'completed');
CREATE TYPE ticket_status AS ENUM ('open', 'inProgress', 'resolved', 'closed');
CREATE TYPE ticket_priority AS ENUM ('low', 'normal', 'high', 'urgent');

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (all app users - signup data)
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employees table (only for actual employees with roles)
CREATE TABLE employees (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    role employee_role NOT NULL DEFAULT 'employee',
    department TEXT,
    employee_number TEXT UNIQUE,
    hire_date TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chat channels table
CREATE TABLE chat_channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages table
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID NOT NULL REFERENCES chat_channels(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_pinned BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Message read receipts
CREATE TABLE message_reads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(message_id, user_id)
);

-- Announcements table
CREATE TABLE announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    priority announcement_priority NOT NULL DEFAULT 'normal',
    published_by UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    target_roles employee_role[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Announcement acknowledgements
CREATE TABLE announcement_acknowledgements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    announcement_id UUID NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    acknowledged_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(announcement_id, user_id)
);

-- Projects table
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    status project_status NOT NULL DEFAULT 'onTrack',
    owner_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    progress DECIMAL(5,2) NOT NULL DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
    due_date TIMESTAMPTZ,
    milestones TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Project team members
CREATE TABLE project_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(project_id, employee_id)
);

-- Support tickets table
CREATE TABLE support_tickets (
    id TEXT PRIMARY KEY,
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    status ticket_status NOT NULL DEFAULT 'open',
    priority ticket_priority NOT NULL DEFAULT 'normal',
    created_by UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    assigned_to UUID REFERENCES employees(id) ON DELETE SET NULL,
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_messages_channel_id ON messages(channel_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX idx_message_reads_message_id ON message_reads(message_id);
CREATE INDEX idx_message_reads_user_id ON message_reads(user_id);
CREATE INDEX idx_announcements_published_by ON announcements(published_by);
CREATE INDEX idx_announcements_created_at ON announcements(created_at DESC);
CREATE INDEX idx_announcement_acks_announcement_id ON announcement_acknowledgements(announcement_id);
CREATE INDEX idx_announcement_acks_user_id ON announcement_acknowledgements(user_id);
CREATE INDEX idx_projects_owner_id ON projects(owner_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_project_members_project_id ON project_members(project_id);
CREATE INDEX idx_project_members_employee_id ON project_members(employee_id);
CREATE INDEX idx_support_tickets_created_by ON support_tickets(created_by);
CREATE INDEX idx_support_tickets_assigned_to ON support_tickets(assigned_to);
CREATE INDEX idx_support_tickets_status ON support_tickets(status);

-- Create updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON employees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_channels_updated_at BEFORE UPDATE ON chat_channels
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON messages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON announcements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_support_tickets_updated_at BEFORE UPDATE ON support_tickets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcement_acknowledgements ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

-- Users policies (all authenticated users can read all users)
CREATE POLICY "Users are viewable by authenticated users" ON users
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Allow trigger function to insert users (SECURITY DEFINER should handle this, but explicit is better)
CREATE POLICY "System can insert users via trigger" ON users
    FOR INSERT WITH CHECK (true);

-- Employees policies (all authenticated users can read all employees)
CREATE POLICY "Employees are viewable by authenticated users" ON employees
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Employees can update their own employee profile" ON employees
    FOR UPDATE USING (auth.uid() = id);

-- Allow trigger function to insert employees (SECURITY DEFINER should handle this, but explicit is better)
CREATE POLICY "System can insert employees via trigger" ON employees
    FOR INSERT WITH CHECK (true);

-- Chat channels policies (all authenticated users can view channels)
CREATE POLICY "Chat channels are viewable by authenticated users" ON chat_channels
    FOR SELECT USING (auth.role() = 'authenticated');

-- Messages policies
CREATE POLICY "Messages are viewable by authenticated users" ON messages
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert messages" ON messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update their own messages" ON messages
    FOR UPDATE USING (auth.uid() = sender_id);

-- Message reads policies
CREATE POLICY "Message reads are viewable by authenticated users" ON message_reads
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert their own message reads" ON message_reads
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Announcements policies
CREATE POLICY "Announcements are viewable by authenticated users" ON announcements
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert announcements if they have permission" ON announcements
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM employees 
            WHERE id = auth.uid() 
            AND role IN ('lead', 'manager', 'admin')
        )
    );

-- Announcement acknowledgements policies
CREATE POLICY "Announcement acknowledgements are viewable by authenticated users" ON announcement_acknowledgements
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert their own acknowledgements" ON announcement_acknowledgements
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Projects policies
CREATE POLICY "Projects are viewable by authenticated users" ON projects
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Managers and admins can insert projects" ON projects
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM employees 
            WHERE id = auth.uid() 
            AND role IN ('manager', 'admin')
        )
    );

CREATE POLICY "Project owners, managers and admins can update projects" ON projects
    FOR UPDATE USING (
        auth.uid() = owner_id OR
        EXISTS (
            SELECT 1 FROM employees 
            WHERE id = auth.uid() 
            AND role IN ('manager', 'admin')
        )
    );

-- Project members policies
CREATE POLICY "Project members are viewable by authenticated users" ON project_members
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Project owners and admins can manage project members" ON project_members
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM projects 
            WHERE id = project_id 
            AND owner_id = auth.uid()
        ) OR
        EXISTS (
            SELECT 1 FROM employees 
            WHERE id = auth.uid() 
            AND role IN ('manager', 'admin')
        )
    );

-- Support tickets policies
CREATE POLICY "Support tickets are viewable by authenticated users" ON support_tickets
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can create support tickets" ON support_tickets
    FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update their own tickets or assigned tickets" ON support_tickets
    FOR UPDATE USING (
        auth.uid() = created_by OR 
        auth.uid() = assigned_to OR
        EXISTS (
            SELECT 1 FROM employees 
            WHERE id = auth.uid() 
            AND role IN ('lead', 'manager', 'admin')
        )
    );

-- Insert default chat channels
INSERT INTO chat_channels (id, name, description) VALUES
    (uuid_generate_v4(), 'general', 'General discussion channel for all employees'),
    (uuid_generate_v4(), 'support', 'Internal support and help desk channel'),
    (uuid_generate_v4(), 'announcements', 'Company announcements and updates');

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

-- Trigger to create user profile on user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

