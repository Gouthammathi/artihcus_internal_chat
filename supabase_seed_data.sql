-- Supabase Seed Data for Development/Testing
-- Run this AFTER setting up the schema and creating auth users

-- This script assumes you've already created auth users through the Supabase dashboard
-- or via the authentication API. The trigger will automatically create employee records.

-- Get channel IDs (they were created by the schema)
DO $$
DECLARE
    general_channel_id UUID;
    support_channel_id UUID;
    announcements_channel_id UUID;
BEGIN
    -- Get channel IDs
    SELECT id INTO general_channel_id FROM chat_channels WHERE name = 'general' LIMIT 1;
    SELECT id INTO support_channel_id FROM chat_channels WHERE name = 'support' LIMIT 1;
    SELECT id INTO announcements_channel_id FROM chat_channels WHERE name = 'announcements' LIMIT 1;

    -- Insert sample messages (assuming employees exist)
    -- You'll need to replace these UUIDs with actual user IDs from your auth.users table
    
    -- Example: Get an admin user ID
    -- SELECT id FROM employees WHERE role = 'admin' LIMIT 1;
    
    -- Uncomment and modify these once you have user IDs:
    /*
    INSERT INTO messages (channel_id, sender_id, content, created_at) VALUES
    (general_channel_id, 'admin-user-id-here', 'Welcome to the Artihcus workspace! Let us know if you need onboarding support.', NOW() - INTERVAL '45 minutes'),
    (general_channel_id, 'employee-user-id-here', 'SAP EWM rollout at the Dubai warehouse completed. Great job team!', NOW() - INTERVAL '18 minutes');
    
    INSERT INTO messages (channel_id, sender_id, content, created_at) VALUES
    (support_channel_id, 'lead-user-id-here', 'Created ticket SUP-2025-031 on integration delays with SAP TM. Need infra input.', NOW() - INTERVAL '2 hours');
    */
    
    -- Add more seed data as needed
    RAISE NOTICE 'Seed data setup complete. Uncomment and modify the INSERT statements with actual user IDs.';
END $$;

-- Sample announcement (uncomment and replace user ID)
/*
INSERT INTO announcements (title, body, priority, published_by, target_roles, created_at) VALUES
(
    'Artihcus Q4 All-Hands',
    'Join the leadership team on Thursday for the Q4 business review and 2026 roadmap.',
    'high',
    'admin-user-id-here',
    ARRAY['employee', 'lead', 'manager', 'admin']::employee_role[],
    NOW() - INTERVAL '1 day'
);
*/

-- Sample project (uncomment and replace user IDs)
/*
INSERT INTO projects (
    name,
    description,
    status,
    owner_id,
    progress,
    due_date,
    milestones,
    created_at
) VALUES
(
    'SAP EWM Implementation — UAE Retail',
    'End-to-end EWM deployment with MFS integration for the UAE flagship warehouse.',
    'onTrack',
    'lead-user-id-here',
    72,
    NOW() + INTERVAL '30 days',
    ARRAY['Blueprint sign-off', 'Integration testing', 'User training'],
    NOW() - INTERVAL '2 months'
);
*/

-- Sample support ticket (uncomment and replace user IDs)
/*
INSERT INTO support_tickets (
    id,
    subject,
    description,
    status,
    priority,
    created_by,
    assigned_to,
    tags,
    created_at
) VALUES
(
    'SUP-2025-031',
    'SAP TM interface latency',
    'Outbound deliveries sync failure to SAP TM for the EMEA region since 03:00 UTC.',
    'inProgress',
    'high',
    'employee-user-id-here',
    'lead-user-id-here',
    ARRAY['SAP TM', 'Integration', 'Urgent'],
    NOW() - INTERVAL '6 hours'
);
*/

-- Helper query to get user IDs after creating them:
-- SELECT id, email, role FROM employees ORDER BY role, email;

