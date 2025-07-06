# Supabase Integration Setup

This document outlines the setup process for integrating Supabase with the mic-for-mac application.

## Prerequisites

1. A Supabase project (create one at [supabase.com](https://supabase.com))
2. Xcode 15.0 or later
3. macOS 13.0 or later

## Environment Variables

Set the following environment variables in your development environment:

```bash
export SUPABASE_URL="https://your-project-ref.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"
export OPENAI_API_KEY="your-openai-api-key"
```

## Development Setup

### Option 1: Environment Variables (Recommended)

1. Create a `.env` file in the project root (not tracked by git):
```bash
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key
OPENAI_API_KEY=your-openai-api-key
```

2. Load environment variables in Xcode:
   - Edit Scheme → Run → Arguments → Environment Variables
   - Add the variables from your `.env` file

### Option 2: UserDefaults (Development Only)

For development purposes, you can set credentials programmatically:

```swift
// In your app's initialization
SupabaseConfig.shared.setDevelopmentCredentials(
    url: "https://your-project-ref.supabase.co",
    anonKey: "your-anon-key"
)
```

## Supabase Project Setup

### 1. Create Database Tables

Run the following SQL in your Supabase SQL editor:

```sql
-- Enable Row Level Security
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- Create user_profiles table
CREATE TABLE user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create dog_profiles table
CREATE TABLE dog_profiles (
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
CREATE TABLE owner_profiles (
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
CREATE TABLE audio_files (
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
CREATE TABLE consultations (
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
CREATE TABLE veterinary_contexts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    selected_dogs TEXT[] NOT NULL,
    visit_purpose TEXT,
    urgency_level TEXT DEFAULT 'routine',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE dog_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE owner_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultations ENABLE ROW LEVEL SECURITY;
ALTER TABLE veterinary_contexts ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Similar policies for other tables...
```

### 2. Create Storage Buckets

1. Go to Storage in your Supabase dashboard
2. Create the following buckets:
   - `audio-files` (public, with RLS)
   - `avatars` (public, with RLS)

### 3. Set Up Storage Policies

```sql
-- Audio files bucket policies
CREATE POLICY "Users can upload own audio files" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'audio-files' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view own audio files" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'audio-files' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete own audio files" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'audio-files' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );
```

## Testing the Setup

1. Build and run the project
2. Check the console for any configuration errors
3. Verify that the Supabase client initializes successfully

## Troubleshooting

### Common Issues

1. **Configuration Error**: Ensure environment variables are set correctly
2. **Network Error**: Check your internet connection and Supabase project status
3. **Authentication Error**: Verify your anon key is correct

### Debug Mode

Enable debug logging by setting the environment variable:
```bash
export SUPABASE_DEBUG=true
```

## Next Steps

After completing this setup, proceed to:
1. Database Schema Design (Issue 2)
2. Core Supabase Service Layer (Issue 3)
3. Data Models & Migration (Issue 4) 