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

-- Create dog_profiles table (updated to match Swift model)
CREATE TABLE IF NOT EXISTS dog_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    breed TEXT,
    date_of_birth DATE,
    weight DECIMAL,
    color TEXT,
    microchip_number TEXT,
    medical_conditions TEXT[],
    medications TEXT[],
    allergies TEXT[],
    special_needs TEXT,
    photo_url TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create medical_records table for dog medical history
CREATE TABLE IF NOT EXISTS medical_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    dog_id UUID REFERENCES dog_profiles(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    diagnosis TEXT,
    treatment TEXT,
    veterinarian TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create current_medications table
CREATE TABLE IF NOT EXISTS current_medications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    dog_id UUID REFERENCES dog_profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    dosage TEXT,
    frequency TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    instructions TEXT,
    prescribed_by TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create surgery_records table
CREATE TABLE IF NOT EXISTS surgery_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    dog_id UUID REFERENCES dog_profiles(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    procedure TEXT NOT NULL,
    surgeon TEXT,
    hospital TEXT,
    complications TEXT,
    recovery_notes TEXT,
    follow_up_required BOOLEAN DEFAULT FALSE,
    follow_up_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create vaccination_records table
CREATE TABLE IF NOT EXISTS vaccination_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    dog_id UUID REFERENCES dog_profiles(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    vaccine_name TEXT NOT NULL,
    administered_by TEXT,
    next_due_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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
ALTER TABLE medical_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE current_medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE surgery_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE vaccination_records ENABLE ROW LEVEL SECURITY;
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

-- Create RLS policies for medical_records
CREATE POLICY "Users can view own medical records" ON medical_records
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM dog_profiles WHERE dog_profiles.id = medical_records.dog_id AND dog_profiles.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert own medical records" ON medical_records
    FOR INSERT WITH CHECK (EXISTS (
        SELECT 1 FROM dog_profiles WHERE dog_profiles.id = medical_records.dog_id AND dog_profiles.user_id = auth.uid()
    ));

CREATE POLICY "Users can update own medical records" ON medical_records
    FOR UPDATE USING (EXISTS (
        SELECT 1 FROM dog_profiles WHERE dog_profiles.id = medical_records.dog_id AND dog_profiles.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete own medical records" ON medical_records
    FOR DELETE USING (EXISTS (
        SELECT 1 FROM dog_profiles WHERE dog_profiles.id = medical_records.dog_id AND dog_profiles.user_id = auth.uid()
    ));

-- Create RLS policies for current_medications
CREATE POLICY "Users can view own current medications" ON current_medications
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM dog_profiles WHERE dog_profiles.id = current_medications.dog_id AND dog_profiles.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert own current medications" ON current_medications
    FOR INSERT WITH CHECK (EXISTS (
        SELECT 1 FROM dog_profiles WHERE dog_profiles.id = current_medications.dog_id AND dog_profiles.user_id = auth.uid()
    ));

CREATE POLICY "Users can update own current medications" ON current_medications
    FOR UPDATE USING (EXISTS (
        SELECT 1 FROM dog_profiles WHERE dog_profiles.id = current_medications.dog_id AND dog_profiles.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete own current medications" ON current_medications
    FOR DELETE USING (EXISTS (
        SELECT 1 FROM dog_profiles WHERE dog_profiles.id = current_medications.dog_id AND dog_profiles.user_id = auth.uid()
    ));

-- Create RLS policies for surgery_records
CREATE POLICY "Users can view own surgery records" ON surgery_records
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM dog_profiles WHERE dog_profiles.id = surgery_records.dog_id AND dog_profiles.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert own surgery records" ON surgery_records
    FOR INSERT WITH CHECK (EXISTS (
        SELECT 1 FROM dog_profiles WHERE dog_profiles.id = surgery_records.dog_id AND dog_profiles.user_id = auth.uid()
    ));

CREATE POLICY "Users can update own surgery records" ON surgery_records
    FOR UPDATE USING (EXISTS (
        SELECT 1 FROM dog_profiles WHERE dog_profiles.id = surgery_records.dog_id AND dog_profiles.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete own surgery records" ON surgery_records
    FOR DELETE USING (EXISTS (
        SELECT 1 FROM dog_profiles WHERE dog_profiles.id = surgery_records.dog_id AND dog_profiles.user_id = auth.uid()
    ));

-- Create RLS policies for vaccination_records
CREATE POLICY "Users can view own vaccination records" ON vaccination_records
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM dog_profiles WHERE dog_profiles.id = vaccination_records.dog_id AND dog_profiles.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert own vaccination records" ON vaccination_records
    FOR INSERT WITH CHECK (EXISTS (
        SELECT 1 FROM dog_profiles WHERE dog_profiles.id = vaccination_records.dog_id AND dog_profiles.user_id = auth.uid()
    ));

CREATE POLICY "Users can update own vaccination records" ON vaccination_records
    FOR UPDATE USING (EXISTS (
        SELECT 1 FROM dog_profiles WHERE dog_profiles.id = vaccination_records.dog_id AND dog_profiles.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete own vaccination records" ON vaccination_records
    FOR DELETE USING (EXISTS (
        SELECT 1 FROM dog_profiles WHERE dog_profiles.id = vaccination_records.dog_id AND dog_profiles.user_id = auth.uid()
    ));

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
CREATE INDEX IF NOT EXISTS idx_medical_records_dog_id ON medical_records(dog_id);
CREATE INDEX IF NOT EXISTS idx_current_medications_dog_id ON current_medications(dog_id);
CREATE INDEX IF NOT EXISTS idx_surgery_records_dog_id ON surgery_records(dog_id);
CREATE INDEX IF NOT EXISTS idx_vaccination_records_dog_id ON vaccination_records(dog_id);
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

-- Temporarily disable RLS for testing
ALTER TABLE dog_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE medical_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE current_medications DISABLE ROW LEVEL SECURITY;
ALTER TABLE surgery_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE vaccination_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE owner_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE audio_files DISABLE ROW LEVEL SECURITY;
ALTER TABLE consultations DISABLE ROW LEVEL SECURITY;
ALTER TABLE veterinary_contexts DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY; 