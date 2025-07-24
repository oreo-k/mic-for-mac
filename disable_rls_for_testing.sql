-- Temporarily disable RLS for testing authentication
-- Run this in Supabase SQL Editor to allow user creation during signup

-- Disable RLS on user_profiles table
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;

-- Disable RLS on other tables for testing
ALTER TABLE owner_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE dog_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE audio_files DISABLE ROW LEVEL SECURITY;
ALTER TABLE veterinary_contexts DISABLE ROW LEVEL SECURITY;
ALTER TABLE consultations DISABLE ROW LEVEL SECURITY;

-- Verify RLS is disabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('user_profiles', 'owner_profiles', 'dog_profiles', 'audio_files', 'veterinary_contexts', 'consultations');

-- Note: This is for testing only. Re-enable RLS for production with:
-- ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE owner_profiles ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE dog_profiles ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE audio_files ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE veterinary_contexts ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE consultations ENABLE ROW LEVEL SECURITY; 