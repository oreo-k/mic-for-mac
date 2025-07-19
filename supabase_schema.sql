-- Complete Supabase Schema for mic-for-mac
-- This schema matches exactly the fields sent by our Swift code

-- DROP EXISTING TABLES (if they exist) to ensure clean schema
DROP TABLE IF EXISTS consultations CASCADE;
DROP TABLE IF EXISTS veterinary_contexts CASCADE;
DROP TABLE IF EXISTS audio_files CASCADE;
DROP TABLE IF EXISTS owner_profiles CASCADE;
DROP TABLE IF EXISTS dog_profiles CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create dog_profiles table (EXACTLY matching SupabaseDogProfile struct)
CREATE TABLE IF NOT EXISTS dog_profiles (
    id TEXT PRIMARY KEY, -- String in Swift, stored as TEXT
    user_id TEXT NOT NULL, -- String in Swift, stored as TEXT
    name TEXT NOT NULL,
    breed TEXT,
    date_of_birth TEXT, -- ISO8601 string in Swift, stored as TEXT
    weight DECIMAL,
    color TEXT,
    microchip_number TEXT,
    medical_conditions TEXT[], -- Array of strings in Swift
    medications TEXT[], -- Array of strings in Swift
    allergies TEXT[], -- Array of strings in Swift
    special_needs TEXT,
    photo_url TEXT,
    notes TEXT,
    created_at TEXT, -- ISO8601 string in Swift, stored as TEXT
    updated_at TEXT -- ISO8601 string in Swift, stored as TEXT
);

-- Create owner_profiles table (EXACTLY matching SupabaseOwnerProfile struct)
CREATE TABLE IF NOT EXISTS owner_profiles (
    id TEXT PRIMARY KEY, -- String in Swift, stored as TEXT
    user_id TEXT NOT NULL, -- String in Swift, stored as TEXT
    full_name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    emergency_contact TEXT,
    created_at TEXT, -- ISO8601 string in Swift, stored as TEXT
    updated_at TEXT -- ISO8601 string in Swift, stored as TEXT
);

-- Create audio_files table (matching AudioFile supabaseFormat)
CREATE TABLE IF NOT EXISTS audio_files (
    id TEXT PRIMARY KEY, -- String in Swift, stored as TEXT
    user_id TEXT NOT NULL, -- String in Swift, stored as TEXT
    filename TEXT NOT NULL,
    file_path TEXT NOT NULL,
    duration DECIMAL,
    transcript TEXT,
    summary TEXT,
    conversation_type TEXT NOT NULL,
    language TEXT NOT NULL,
    transcription_cost DECIMAL DEFAULT 0,
    summarization_cost DECIMAL DEFAULT 0,
    token_count INTEGER DEFAULT 0,
    is_pending BOOLEAN DEFAULT FALSE,
    veterinary_context JSONB, -- JSON object for veterinary context
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create veterinary_contexts table (matching VeterinaryContext supabaseFormat)
CREATE TABLE IF NOT EXISTS veterinary_contexts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL,
    selected_dogs TEXT[] NOT NULL, -- Array of dog IDs as strings
    visit_purpose TEXT,
    urgency_level TEXT DEFAULT 'routine',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create consultations table
CREATE TABLE IF NOT EXISTS consultations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL,
    audio_file_id TEXT REFERENCES audio_files(id) ON DELETE CASCADE,
    consultation_type TEXT NOT NULL,
    summary TEXT,
    recommendations TEXT,
    follow_up_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS) on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE dog_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE owner_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE veterinary_contexts ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for user_profiles
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Create RLS policies for dog_profiles
CREATE POLICY "Users can view own dog profiles" ON dog_profiles
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own dog profiles" ON dog_profiles
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own dog profiles" ON dog_profiles
    FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own dog profiles" ON dog_profiles
    FOR DELETE USING (auth.uid()::text = user_id);

-- Create RLS policies for owner_profiles
CREATE POLICY "Users can view own owner profiles" ON owner_profiles
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own owner profiles" ON owner_profiles
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own owner profiles" ON owner_profiles
    FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own owner profiles" ON owner_profiles
    FOR DELETE USING (auth.uid()::text = user_id);

-- Create RLS policies for audio_files
CREATE POLICY "Users can view own audio files" ON audio_files
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own audio files" ON audio_files
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own audio files" ON audio_files
    FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own audio files" ON audio_files
    FOR DELETE USING (auth.uid()::text = user_id);

-- Create RLS policies for veterinary_contexts
CREATE POLICY "Users can view own veterinary contexts" ON veterinary_contexts
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own veterinary contexts" ON veterinary_contexts
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own veterinary contexts" ON veterinary_contexts
    FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own veterinary contexts" ON veterinary_contexts
    FOR DELETE USING (auth.uid()::text = user_id);

-- Create RLS policies for consultations
CREATE POLICY "Users can view own consultations" ON consultations
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own consultations" ON consultations
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own consultations" ON consultations
    FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own consultations" ON consultations
    FOR DELETE USING (auth.uid()::text = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_dog_profiles_user_id ON dog_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_owner_profiles_user_id ON owner_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_files_user_id ON audio_files(user_id);
CREATE INDEX IF NOT EXISTS idx_veterinary_contexts_user_id ON veterinary_contexts(user_id);
CREATE INDEX IF NOT EXISTS idx_consultations_user_id ON consultations(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_files_created_at ON audio_files(created_at DESC);

-- Create function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, created_at, updated_at)
    VALUES (NEW.id, NEW.email, NOW(), NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user creation
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- TEMPORARILY DISABLE RLS FOR TESTING (without authentication)
ALTER TABLE dog_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE owner_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE audio_files DISABLE ROW LEVEL SECURITY;
ALTER TABLE veterinary_contexts DISABLE ROW LEVEL SECURITY;
ALTER TABLE consultations DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY; 