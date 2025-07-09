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

-- Avatar bucket policies
CREATE POLICY "Users can upload own avatars" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'avatars' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view own avatars" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'avatars' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete own avatars" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'avatars' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );