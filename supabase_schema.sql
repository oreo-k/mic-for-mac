-- Supabase Schema for mic-for-mac
-- Run this in your Supabase SQL Editor

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create dog_profiles table
CREATE TABLE IF NOT EXISTS dog_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    breed TEXT,
    age INTEGER,
    weight DECIMAL,
    medical_conditions TEXT[],
    medications TEXT[],
    allergies TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create owner_profiles table
CREATE TABLE IF NOT EXISTS owner_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    emergency_contact TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create audio_files table
CREATE TABLE IF NOT EXISTS audio_files (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    filename TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    duration DECIMAL,
    conversation_type TEXT NOT NULL,
    language TEXT NOT NULL,
    transcript TEXT,
    summary TEXT,
    transcription_cost DECIMAL DEFAULT 0,
    summarization_cost DECIMAL DEFAULT 0,
    token_count INTEGER DEFAULT 0,
    is_processed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create consultations table
CREATE TABLE IF NOT EXISTS consultations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    audio_file_id UUID REFERENCES audio_files(id) ON DELETE CASCADE,
    consultation_type TEXT NOT NULL,
    summary TEXT,
    recommendations TEXT,
    follow_up_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create veterinary_contexts table
CREATE TABLE IF NOT EXISTS veterinary_contexts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    selected_dogs TEXT[] NOT NULL,
    visit_purpose TEXT,
    urgency_level TEXT DEFAULT 'routine',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS) on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE dog_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE owner_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultations ENABLE ROW LEVEL SECURITY;
ALTER TABLE veterinary_contexts ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for user_profiles
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Create RLS policies for dog_profiles
CREATE POLICY "Users can view own dog profiles" ON dog_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own dog profiles" ON dog_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own dog profiles" ON dog_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own dog profiles" ON dog_profiles
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for owner_profiles
CREATE POLICY "Users can view own owner profile" ON owner_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own owner profile" ON owner_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own owner profile" ON owner_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own owner profile" ON owner_profiles
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for audio_files
CREATE POLICY "Users can view own audio files" ON audio_files
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own audio files" ON audio_files
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own audio files" ON audio_files
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own audio files" ON audio_files
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for consultations
CREATE POLICY "Users can view own consultations" ON consultations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own consultations" ON consultations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own consultations" ON consultations
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own consultations" ON consultations
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for veterinary_contexts
CREATE POLICY "Users can view own veterinary contexts" ON veterinary_contexts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own veterinary contexts" ON veterinary_contexts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own veterinary contexts" ON veterinary_contexts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own veterinary contexts" ON veterinary_contexts
    FOR DELETE USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_dog_profiles_user_id ON dog_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_owner_profiles_user_id ON owner_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_files_user_id ON audio_files(user_id);
CREATE INDEX IF NOT EXISTS idx_consultations_user_id ON consultations(user_id);
CREATE INDEX IF NOT EXISTS idx_veterinary_contexts_user_id ON veterinary_contexts(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_files_created_at ON audio_files(created_at DESC);

-- Create a function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'full_name');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create user profile
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated; 