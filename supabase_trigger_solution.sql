-- Complete Supabase Authentication Solution with Database Triggers
-- This fixes the chicken-and-egg problem for new user signup

-- Step 1: Ensure we have the correct schema
-- (Run supabase_schema_fixed.sql first if you haven't already)

-- Step 2: Create the trigger function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_role TEXT;
BEGIN
    -- Determine user role based on email and any admin configuration
    -- For now, default to 'user' - we can enhance this later
    user_role := 'user';
    
    -- Check if email is in admin list (you can customize this)
    IF NEW.email = 'testadmintest@gmail.com' THEN
        user_role := 'admin';
    END IF;
    
    -- Insert user profile with determined role
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

-- Step 3: Create the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Step 4: Re-enable RLS with proper policies
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE owner_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE dog_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE veterinary_contexts ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultations ENABLE ROW LEVEL SECURITY;

-- Step 5: Drop existing policies and recreate them properly
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can view all user profiles" ON user_profiles;

-- Step 6: Create proper RLS policies for user_profiles
-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid()::text = user_id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid()::text = user_id);

-- Allow user profile creation (trigger handles this, but policy needed for RLS)
CREATE POLICY "Allow user profile creation" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- Admins can view all user profiles
CREATE POLICY "Admins can view all user profiles" ON user_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid()::text AND role = 'admin'
        )
    );

-- Step 7: Test the trigger
-- You can test this by checking if the trigger was created:
SELECT 
    trigger_name, 
    event_manipulation, 
    action_statement 
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- Step 8: Verify the setup
-- Check if RLS is enabled and policies exist
SELECT 
    schemaname, 
    tablename, 
    rowsecurity,
    CASE 
        WHEN rowsecurity THEN 'RLS Enabled'
        ELSE 'RLS Disabled'
    END as rls_status
FROM pg_tables 
WHERE tablename = 'user_profiles';

-- List all policies on user_profiles
SELECT 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual 
FROM pg_policies 
WHERE tablename = 'user_profiles';

-- Step 9: Optional - Add admin role assignment function
-- This allows you to assign admin role to existing users
CREATE OR REPLACE FUNCTION public.assign_admin_role(user_email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE user_profiles 
    SET role = 'admin', updated_at = NOW()
    WHERE email = user_email;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.assign_admin_role(TEXT) TO authenticated;

-- Usage example:
-- SELECT assign_admin_role('test@gmail.com'); 