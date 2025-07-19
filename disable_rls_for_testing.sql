-- Temporarily disable RLS for testing
-- Run this in your Supabase SQL Editor

-- Disable RLS on dog_profiles table
ALTER TABLE dog_profiles DISABLE ROW LEVEL SECURITY;

-- Disable RLS on medical_records table
ALTER TABLE medical_records DISABLE ROW LEVEL SECURITY;

-- Disable RLS on current_medications table
ALTER TABLE current_medications DISABLE ROW LEVEL SECURITY;

-- Disable RLS on surgery_records table
ALTER TABLE surgery_records DISABLE ROW LEVEL SECURITY;

-- Disable RLS on vaccination_records table
ALTER TABLE vaccination_records DISABLE ROW LEVEL SECURITY;

-- Disable RLS on owner_profiles table
ALTER TABLE owner_profiles DISABLE ROW LEVEL SECURITY;

-- Disable RLS on audio_files table
ALTER TABLE audio_files DISABLE ROW LEVEL SECURITY;

-- Disable RLS on consultations table
ALTER TABLE consultations DISABLE ROW LEVEL SECURITY;

-- Disable RLS on veterinary_contexts table
ALTER TABLE veterinary_contexts DISABLE ROW LEVEL SECURITY;

-- Disable RLS on user_profiles table
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;

-- Note: This is for testing only. Re-enable RLS when implementing authentication. 