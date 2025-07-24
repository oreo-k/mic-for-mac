-- COMPLETE FIX for Infinite Recursion in RLS Policies
-- This fixes ALL recursive policies across ALL tables

-- Step 1: Drop ALL existing policies that might cause recursion
-- User profiles policies
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can view all user profiles" ON user_profiles;
DROP POLICY IF EXISTS "Allow user profile creation" ON user_profiles;

-- Owner profiles policies
DROP POLICY IF EXISTS "Users can view own owner profiles" ON owner_profiles;
DROP POLICY IF EXISTS "Users can update own owner profiles" ON owner_profiles;
DROP POLICY IF EXISTS "Users can insert own owner profiles" ON owner_profiles;
DROP POLICY IF EXISTS "Users can delete own owner profiles" ON owner_profiles;
DROP POLICY IF EXISTS "Admins can view shared owner profiles" ON owner_profiles;
DROP POLICY IF EXISTS "Admins can update shared owner profiles" ON owner_profiles;

-- Dog profiles policies
DROP POLICY IF EXISTS "Users can view own dog profiles" ON dog_profiles;
DROP POLICY IF EXISTS "Users can update own dog profiles" ON dog_profiles;
DROP POLICY IF EXISTS "Users can insert own dog profiles" ON dog_profiles;
DROP POLICY IF EXISTS "Users can delete own dog profiles" ON dog_profiles;
DROP POLICY IF EXISTS "Admins can view shared dog profiles" ON dog_profiles;
DROP POLICY IF EXISTS "Admins can update shared dog profiles" ON dog_profiles;

-- Audio files policies
DROP POLICY IF EXISTS "Users can view own audio files" ON audio_files;
DROP POLICY IF EXISTS "Users can update own audio files" ON audio_files;
DROP POLICY IF EXISTS "Users can insert own audio files" ON audio_files;
DROP POLICY IF EXISTS "Users can delete own audio files" ON audio_files;
DROP POLICY IF EXISTS "Admins can view audio files for shared dogs" ON audio_files;

-- Veterinary contexts policies
DROP POLICY IF EXISTS "Users can view own veterinary contexts" ON veterinary_contexts;
DROP POLICY IF EXISTS "Users can update own veterinary contexts" ON veterinary_contexts;
DROP POLICY IF EXISTS "Users can insert own veterinary contexts" ON veterinary_contexts;
DROP POLICY IF EXISTS "Users can delete own veterinary contexts" ON veterinary_contexts;
DROP POLICY IF EXISTS "Admins can view veterinary contexts for shared dogs" ON veterinary_contexts;

-- Consultations policies
DROP POLICY IF EXISTS "Users can view own consultations" ON consultations;
DROP POLICY IF EXISTS "Users can update own consultations" ON consultations;
DROP POLICY IF EXISTS "Users can insert own consultations" ON consultations;
DROP POLICY IF EXISTS "Users can delete own consultations" ON consultations;
DROP POLICY IF EXISTS "Admins can view consultations for shared dogs" ON consultations;
DROP POLICY IF EXISTS "Admins can update consultations for shared dogs" ON consultations;
DROP POLICY IF EXISTS "Admins can insert consultations for shared dogs" ON consultations;

-- Step 2: Create admin check function (non-recursive)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if the current user's email is in the admin list
    -- This avoids any database queries that could cause recursion
    RETURN auth.jwt() ->> 'email' IN ('testadmintest@gmail.com');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Create NON-RECURSIVE policies for user_profiles
-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid()::text = user_id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid()::text = user_id);

-- Allow user profile creation (trigger handles this, but policy needed for RLS)
CREATE POLICY "Allow user profile creation" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- Admins can view all user profiles (NON-RECURSIVE)
CREATE POLICY "Admins can view all user profiles" ON user_profiles
    FOR SELECT USING (public.is_admin());

-- Step 4: Create NON-RECURSIVE policies for owner_profiles
-- Users can view their own owner profiles
CREATE POLICY "Users can view own owner profiles" ON owner_profiles
    FOR SELECT USING (user_id = auth.uid()::text);

-- Users can update their own owner profiles
CREATE POLICY "Users can update own owner profiles" ON owner_profiles
    FOR UPDATE USING (user_id = auth.uid()::text);

-- Users can insert their own owner profiles
CREATE POLICY "Users can insert own owner profiles" ON owner_profiles
    FOR INSERT WITH CHECK (user_id = auth.uid()::text);

-- Users can delete their own owner profiles
CREATE POLICY "Users can delete own owner profiles" ON owner_profiles
    FOR DELETE USING (user_id = auth.uid()::text);

-- Admins can view owner profiles shared with admin (NON-RECURSIVE)
CREATE POLICY "Admins can view shared owner profiles" ON owner_profiles
    FOR SELECT USING (shared_with_admin = TRUE AND public.is_admin());

-- Admins can update owner profiles shared with admin (NON-RECURSIVE)
CREATE POLICY "Admins can update shared owner profiles" ON owner_profiles
    FOR UPDATE USING (shared_with_admin = TRUE AND public.is_admin());

-- Step 5: Create NON-RECURSIVE policies for dog_profiles
-- Users can view their own dog profiles
CREATE POLICY "Users can view own dog profiles" ON dog_profiles
    FOR SELECT USING (user_id = auth.uid()::text);

-- Users can update their own dog profiles
CREATE POLICY "Users can update own dog profiles" ON dog_profiles
    FOR UPDATE USING (user_id = auth.uid()::text);

-- Users can insert their own dog profiles
CREATE POLICY "Users can insert own dog profiles" ON dog_profiles
    FOR INSERT WITH CHECK (user_id = auth.uid()::text);

-- Users can delete their own dog profiles
CREATE POLICY "Users can delete own dog profiles" ON dog_profiles
    FOR DELETE USING (user_id = auth.uid()::text);

-- Admins can view dog profiles shared with admin (NON-RECURSIVE)
CREATE POLICY "Admins can view shared dog profiles" ON dog_profiles
    FOR SELECT USING (shared_with_admin = TRUE AND public.is_admin());

-- Admins can update dog profiles shared with admin (NON-RECURSIVE)
CREATE POLICY "Admins can update shared dog profiles" ON dog_profiles
    FOR UPDATE USING (shared_with_admin = TRUE AND public.is_admin());

-- Step 6: Create NON-RECURSIVE policies for audio_files
-- Users can view their own audio files
CREATE POLICY "Users can view own audio files" ON audio_files
    FOR SELECT USING (user_id = auth.uid()::text);

-- Users can update their own audio files
CREATE POLICY "Users can update own audio files" ON audio_files
    FOR UPDATE USING (user_id = auth.uid()::text);

-- Users can insert their own audio files
CREATE POLICY "Users can insert own audio files" ON audio_files
    FOR INSERT WITH CHECK (user_id = auth.uid()::text);

-- Users can delete their own audio files
CREATE POLICY "Users can delete own audio files" ON audio_files
    FOR DELETE USING (user_id = auth.uid()::text);

-- Admins can view audio files for shared dogs (NON-RECURSIVE)
CREATE POLICY "Admins can view audio files for shared dogs" ON audio_files
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM dog_profiles 
            WHERE dog_id = audio_files.dog_id AND shared_with_admin = TRUE
        ) AND public.is_admin()
    );

-- Step 7: Create NON-RECURSIVE policies for veterinary_contexts
-- Users can view their own veterinary contexts
CREATE POLICY "Users can view own veterinary contexts" ON veterinary_contexts
    FOR SELECT USING (user_id = auth.uid()::text);

-- Users can update their own veterinary contexts
CREATE POLICY "Users can update own veterinary contexts" ON veterinary_contexts
    FOR UPDATE USING (user_id = auth.uid()::text);

-- Users can insert their own veterinary contexts
CREATE POLICY "Users can insert own veterinary contexts" ON veterinary_contexts
    FOR INSERT WITH CHECK (user_id = auth.uid()::text);

-- Users can delete their own veterinary contexts
CREATE POLICY "Users can delete own veterinary contexts" ON veterinary_contexts
    FOR DELETE USING (user_id = auth.uid()::text);

-- Admins can view veterinary contexts for shared dogs (NON-RECURSIVE)
CREATE POLICY "Admins can view veterinary contexts for shared dogs" ON veterinary_contexts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM dog_profiles 
            WHERE dog_id = veterinary_contexts.dog_id AND shared_with_admin = TRUE
        ) AND public.is_admin()
    );

-- Step 8: Create NON-RECURSIVE policies for consultations
-- Users can view their own consultations
CREATE POLICY "Users can view own consultations" ON consultations
    FOR SELECT USING (user_id = auth.uid()::text);

-- Users can update their own consultations
CREATE POLICY "Users can update own consultations" ON consultations
    FOR UPDATE USING (user_id = auth.uid()::text);

-- Users can insert their own consultations
CREATE POLICY "Users can insert own consultations" ON consultations
    FOR INSERT WITH CHECK (user_id = auth.uid()::text);

-- Users can delete their own consultations
CREATE POLICY "Users can delete own consultations" ON consultations
    FOR DELETE USING (user_id = auth.uid()::text);

-- Admins can view consultations for shared dogs (NON-RECURSIVE)
CREATE POLICY "Admins can view consultations for shared dogs" ON consultations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM dog_profiles 
            WHERE dog_id = consultations.dog_id AND shared_with_admin = TRUE
        ) AND public.is_admin()
    );

-- Admins can update consultations for shared dogs (NON-RECURSIVE)
CREATE POLICY "Admins can update consultations for shared dogs" ON consultations
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM dog_profiles 
            WHERE dog_id = consultations.dog_id AND shared_with_admin = TRUE
        ) AND public.is_admin()
    );

-- Admins can insert consultations for shared dogs (NON-RECURSIVE)
CREATE POLICY "Admins can insert consultations for shared dogs" ON consultations
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM dog_profiles 
            WHERE dog_id = consultations.dog_id AND shared_with_admin = TRUE
        ) AND public.is_admin()
    );

-- Step 9: Verify the fix
-- Check if RLS is enabled
SELECT 
    schemaname, 
    tablename, 
    rowsecurity,
    CASE 
        WHEN rowsecurity THEN 'RLS Enabled'
        ELSE 'RLS Disabled'
    END as rls_status
FROM pg_tables 
WHERE tablename IN ('user_profiles', 'owner_profiles', 'dog_profiles', 'audio_files', 'veterinary_contexts', 'consultations');

-- List all policies to verify they're non-recursive
SELECT 
    tablename,
    policyname, 
    cmd, 
    qual 
FROM pg_policies 
WHERE tablename IN ('user_profiles', 'owner_profiles', 'dog_profiles', 'audio_files', 'veterinary_contexts', 'consultations')
ORDER BY tablename, policyname;

-- Test the admin function
SELECT public.is_admin() as is_admin_check;

-- Step 10: Test the trigger (if it exists)
SELECT 
    trigger_name, 
    event_manipulation, 
    action_statement 
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- Step 11: Optional - Add admin role assignment function
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
-- SELECT assign_admin_role('testadmintest@gmail.com'); 