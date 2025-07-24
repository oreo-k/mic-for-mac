-- Fix for RLS blocking trigger function
-- This allows the trigger to create user profiles while maintaining security

-- Step 1: Drop the problematic INSERT policy
DROP POLICY IF EXISTS "Allow user profile creation" ON user_profiles;

-- Step 2: Create a new INSERT policy that allows trigger creation
CREATE POLICY "Allow user profile creation" ON user_profiles
    FOR INSERT WITH CHECK (
        -- Allow if user is creating their own profile
        auth.uid()::text = user_id
        OR
        -- Allow if this is a trigger-created profile (user_id matches the new user)
        -- The trigger function runs with SECURITY DEFINER, so we need to be more permissive
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE id::text = user_id
        )
    );

-- Step 3: Alternative approach - Create a more permissive policy for trigger
-- If the above doesn't work, try this instead:
-- DROP POLICY IF EXISTS "Allow user profile creation" ON user_profiles;
-- CREATE POLICY "Allow user profile creation" ON user_profiles
--     FOR INSERT WITH CHECK (true); -- Allow all inserts (trigger handles security)

-- Step 4: Verify the trigger function has proper permissions
-- Make sure the trigger function can bypass RLS
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_role TEXT;
BEGIN
    -- Determine user role based on email and any admin configuration
    user_role := 'user';
    
    -- Check if email is in admin list
    IF NEW.email = 'testadmintest@gmail.com' THEN
        user_role := 'admin';
    END IF;
    
    -- Insert user profile with determined role
    -- This should now work with the updated RLS policy
    INSERT INTO public.user_profiles (
        user_id, 
        email, 
        role, 
        created_at, 
        updated_at
    ) VALUES (
        NEW.id, 
        NEW.email, 
        user_role, 
        NOW(), 
        NOW()
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the signup
        RAISE WARNING 'Failed to create user profile for %: %', NEW.email, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Test the trigger
SELECT 
    trigger_name, 
    event_manipulation, 
    action_statement 
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- Step 6: Verify RLS policies
SELECT 
    tablename,
    policyname, 
    cmd, 
    qual 
FROM pg_policies 
WHERE tablename = 'user_profiles'
ORDER BY policyname;

-- Step 7: Test the admin function
SELECT public.is_admin() as is_admin_check;

-- Step 8: Optional - If still having issues, temporarily disable RLS for testing
-- Uncomment the lines below if you need to test without RLS temporarily
-- ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;
-- SELECT 'RLS temporarily disabled for user_profiles' as status;

-- Step 9: Re-enable RLS (if you disabled it for testing)
-- ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
-- SELECT 'RLS re-enabled for user_profiles' as status; 