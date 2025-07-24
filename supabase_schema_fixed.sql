-- Complete Supabase Schema for mic-for-mac (FIXED VERSION)
-- This schema matches exactly the fields sent by our Swift code

-- Drop existing tables to ensure clean schema
DROP TABLE IF EXISTS consultations CASCADE;
DROP TABLE IF EXISTS veterinary_contexts CASCADE;
DROP TABLE IF EXISTS audio_files CASCADE;
DROP TABLE IF EXISTS dog_profiles CASCADE;
DROP TABLE IF EXISTS owner_profiles CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Create user_profiles table with role-based access
CREATE TABLE user_profiles (
    user_id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Create owner_profiles table with data sharing
CREATE TABLE owner_profiles (
    owner_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    emergency_contact TEXT,
    shared_with_admin BOOLEAN DEFAULT FALSE,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Create dog_profiles table with data sharing
CREATE TABLE dog_profiles (
    dog_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    breed TEXT,
    date_of_birth TEXT NOT NULL,
    weight REAL,
    color TEXT,
    microchip_number TEXT,
    medical_conditions TEXT[],
    medications TEXT[],
    allergies TEXT[],
    special_needs TEXT,
    photo_url TEXT,
    notes TEXT,
    shared_with_admin BOOLEAN DEFAULT FALSE,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Create audio_files table
CREATE TABLE audio_files (
    audio_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    dog_id TEXT REFERENCES dog_profiles(dog_id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size INTEGER,
    duration REAL,
    recording_date TEXT NOT NULL,
    notes TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Create veterinary_contexts table
CREATE TABLE veterinary_contexts (
    context_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    dog_id TEXT REFERENCES dog_profiles(dog_id) ON DELETE CASCADE,
    context_type TEXT NOT NULL,
    context_data TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Create consultations table
CREATE TABLE consultations (
    consultation_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    dog_id TEXT REFERENCES dog_profiles(dog_id) ON DELETE CASCADE,
    consultation_date TEXT NOT NULL,
    symptoms TEXT,
    diagnosis TEXT,
    treatment_plan TEXT,
    follow_up_date TEXT,
    notes TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Create indexes for better performance
CREATE INDEX idx_owner_profiles_user_id ON owner_profiles(user_id);
CREATE INDEX idx_dog_profiles_user_id ON dog_profiles(user_id);
CREATE INDEX idx_audio_files_user_id ON audio_files(user_id);
CREATE INDEX idx_audio_files_dog_id ON audio_files(dog_id);
CREATE INDEX idx_veterinary_contexts_user_id ON veterinary_contexts(user_id);
CREATE INDEX idx_veterinary_contexts_dog_id ON veterinary_contexts(dog_id);
CREATE INDEX idx_consultations_user_id ON consultations(user_id);
CREATE INDEX idx_consultations_dog_id ON consultations(dog_id);
CREATE INDEX idx_user_profiles_role ON user_profiles(role);
CREATE INDEX idx_dog_profiles_shared_with_admin ON dog_profiles(shared_with_admin);
CREATE INDEX idx_owner_profiles_shared_with_admin ON owner_profiles(shared_with_admin);

-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE owner_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE dog_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE veterinary_contexts ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_profiles
-- Users can only access their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid()::text = user_id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid()::text = user_id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- Admins can view all user profiles
CREATE POLICY "Admins can view all user profiles" ON user_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid()::text AND role = 'admin'
        )
    );

-- RLS Policies for owner_profiles
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

-- Admins can view owner profiles shared with admin
CREATE POLICY "Admins can view shared owner profiles" ON owner_profiles
    FOR SELECT USING (
        shared_with_admin = TRUE AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid()::text AND role = 'admin'
        )
    );

-- Admins can update owner profiles shared with admin
CREATE POLICY "Admins can update shared owner profiles" ON owner_profiles
    FOR UPDATE USING (
        shared_with_admin = TRUE AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid()::text AND role = 'admin'
        )
    );

-- RLS Policies for dog_profiles
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

-- Admins can view dog profiles shared with admin
CREATE POLICY "Admins can view shared dog profiles" ON dog_profiles
    FOR SELECT USING (
        shared_with_admin = TRUE AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid()::text AND role = 'admin'
        )
    );

-- Admins can update dog profiles shared with admin
CREATE POLICY "Admins can update shared dog profiles" ON dog_profiles
    FOR UPDATE USING (
        shared_with_admin = TRUE AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid()::text AND role = 'admin'
        )
    );

-- RLS Policies for audio_files
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

-- Admins can view audio files for shared dogs
CREATE POLICY "Admins can view audio files for shared dogs" ON audio_files
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM dog_profiles 
            WHERE dog_id = audio_files.dog_id AND shared_with_admin = TRUE
        ) AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid()::text AND role = 'admin'
        )
    );

-- RLS Policies for veterinary_contexts
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

-- Admins can view veterinary contexts for shared dogs
CREATE POLICY "Admins can view veterinary contexts for shared dogs" ON veterinary_contexts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM dog_profiles 
            WHERE dog_id = veterinary_contexts.dog_id AND shared_with_admin = TRUE
        ) AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid()::text AND role = 'admin'
        )
    );

-- RLS Policies for consultations
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

-- Admins can view consultations for shared dogs
CREATE POLICY "Admins can view consultations for shared dogs" ON consultations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM dog_profiles 
            WHERE dog_id = consultations.dog_id AND shared_with_admin = TRUE
        ) AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid()::text AND role = 'admin'
        )
    );

-- Admins can update consultations for shared dogs
CREATE POLICY "Admins can update consultations for shared dogs" ON consultations
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM dog_profiles 
            WHERE dog_id = consultations.dog_id AND shared_with_admin = TRUE
        ) AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid()::text AND role = 'admin'
        )
    );

-- Admins can insert consultations for shared dogs
CREATE POLICY "Admins can insert consultations for shared dogs" ON consultations
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM dog_profiles 
            WHERE dog_id = consultations.dog_id AND shared_with_admin = TRUE
        ) AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid()::text AND role = 'admin'
        )
    ); 