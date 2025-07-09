import Foundation
import Supabase
import Combine

// MARK: - Stub Types (will be replaced with actual Supabase types)
struct User {
    let id: String
    let email: String
}

struct RealtimeChannel {
    // Stub for real-time channel
}

struct RealtimePostgresChangesPayload {
    // Stub for real-time payload
}

struct FileOptions {
    let contentType: String
    
    init(contentType: String) {
        self.contentType = contentType
    }
}

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    // MARK: - Properties
    private var client: SupabaseClient
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var currentUser: Auth.User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Initialization
    private init() {
        // Initialize with configuration
        guard let url = URL(string: SupabaseConfig.shared.supabaseURL),
              !SupabaseConfig.shared.supabaseAnonKey.isEmpty else {
            fatalError("Supabase configuration is missing")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.shared.supabaseAnonKey
        )
        
        // Check initial authentication state
        checkAuthenticationState()
    }
    
    // MARK: - Authentication Methods
    func signUp(email: String, password: String) async throws -> Auth.User {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            
            await MainActor.run {
                self.currentUser = response.user
                self.isAuthenticated = true
            }
            
            return response.user
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws -> Auth.User {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            await MainActor.run {
                self.currentUser = response.user
                self.isAuthenticated = true
            }
            
            return response.user
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await client.auth.signOut()
            
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    private func checkAuthenticationState() {
        Task {
            do {
                let session = try await client.auth.session
                await MainActor.run {
                    self.currentUser = session.user
                    self.isAuthenticated = true
                }
            } catch {
                await MainActor.run {
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
            }
        }
    }
    
    // MARK: - Database Operations
    
    // User Profiles
    func createUserProfile(_ profile: UserProfile) async throws {
        try await client.database
            .from(SupabaseConfig.Tables.userProfiles)
            .insert(profile)
            .execute()
    }
    
    func getUserProfile(userId: UUID) async throws -> UserProfile? {
        let response: [UserProfile] = try await client.database
            .from(SupabaseConfig.Tables.userProfiles)
            .select()
            .eq("id", value: userId)
            .execute()
            .value
        
        return response.first
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        try await client.database
            .from(SupabaseConfig.Tables.userProfiles)
            .update(profile)
            .eq("id", value: profile.id)
            .execute()
    }
    
    // Dog Profiles
    func createDogProfile(_ profile: DogProfile) async throws {
        try await client.database
            .from(SupabaseConfig.Tables.dogProfiles)
            .insert(profile)
            .execute()
    }
    
    func getDogProfiles(userId: UUID) async throws -> [DogProfile] {
        let response: [DogProfile] = try await client.database
            .from(SupabaseConfig.Tables.dogProfiles)
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return response
    }
    
    func updateDogProfile(_ profile: DogProfile) async throws {
        try await client.database
            .from(SupabaseConfig.Tables.dogProfiles)
            .update(profile)
            .eq("id", value: profile.id)
            .execute()
    }
    
    func deleteDogProfile(id: UUID) async throws {
        try await client.database
            .from(SupabaseConfig.Tables.dogProfiles)
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // Audio Files
    func createAudioFile(_ audioFile: AudioFile) async throws {
        try await client.database
            .from(SupabaseConfig.Tables.audioFiles)
            .insert(audioFile)
            .execute()
    }
    
    func getAudioFiles(userId: UUID) async throws -> [AudioFile] {
        let response: [AudioFile] = try await client.database
            .from(SupabaseConfig.Tables.audioFiles)
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    func updateAudioFile(_ audioFile: AudioFile) async throws {
        try await client.database
            .from(SupabaseConfig.Tables.audioFiles)
            .update(audioFile)
            .eq("id", value: audioFile.id)
            .execute()
    }
    
    func deleteAudioFile(id: UUID) async throws {
        try await client.database
            .from(SupabaseConfig.Tables.audioFiles)
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - File Storage Operations
    
    func uploadAudioFile(_ fileURL: URL, fileName: String) async throws -> String {
        let fileData = try Data(contentsOf: fileURL)
        let path = try await client.storage
            .from(SupabaseConfig.Storage.audioFiles)
            .upload(
                path: fileName,
                file: fileData,
                options: Storage.FileOptions(contentType: "audio/m4a")
            )
        return path
    }
    
    func downloadAudioFile(path: String) async throws -> URL {
        let data = try await client.storage
            .from(SupabaseConfig.Storage.audioFiles)
            .download(path: path)
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(path)
        try data.write(to: tempURL)
        
        return tempURL
    }
    
    func deleteAudioFileFromStorage(path: String) async throws {
        _ = try await client.storage
            .from(SupabaseConfig.Storage.audioFiles)
            .remove(paths: [path])
    }
    
    // MARK: - Real-time Subscriptions (RealtimeChannelV2)
    
    func subscribeToAudioFiles(userId: UUID) {
        let channel = client.realtime.channel("audio_files")
        channel.on(event: "postgres_changes", filter: ChannelFilter("table=audio_files")) { [weak self] (message: RealtimeMessage) in
            self?.handleAudioFileUpdate(message)
        }
        Task {
            await channel.subscribe()
        }
    }
    
    private func handleAudioFileUpdate(_ message: RealtimeMessage) {
        // Handle real-time updates for audio files
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Data Models for Supabase

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let email: String
    var fullName: String?
    var avatarUrl: String?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, email, fullName = "full_name", avatarUrl = "avatar_url"
        case createdAt = "created_at", updatedAt = "updated_at"
    }
}

// Extension to convert existing models to Supabase format
extension DogProfile {
    var supabaseFormat: [String: Any] {
        return [
            "id": id.uuidString,
            "user_id": "", // Will be set by the service
            "name": name,
            "breed": breed,
            "date_of_birth": dateOfBirth,
            "weight": weight,
            "color": color,
            "microchip_number": microchipNumber,
            "medical_history": medicalHistory,
            "current_medications": currentMedications,
            "surgeries": surgeries,
            "vaccinations": vaccinations,
            "allergies": allergies,
            "special_needs": specialNeeds,
            "photo_url": photoURL,
            "notes": notes,
            "created_at": Date(),
            "updated_at": Date()
        ]
    }
}

extension AudioFile {
    var supabaseFormat: [String: Any] {
        return [
            "id": id.uuidString,
            "user_id": "", // Will be set by the service
            "filename": filename,
            "file_path": url.lastPathComponent,
            "duration": duration,
            "transcript": transcript,
            "summary": summary,
            "conversation_type": conversationType.rawValue,
            "language": language.rawValue,
            "transcription_cost": transcriptionCost,
            "summarization_cost": summarizationCost,
            "token_count": tokenCount,
            "is_pending": isPending,
            "veterinary_context": veterinaryContext?.supabaseFormat as Any,
            "created_at": date,
            "updated_at": Date()
        ]
    }
}

extension VeterinaryContext {
    var supabaseFormat: [String: Any] {
        return [
            "selected_dogs": Array(selectedDogs).map { $0.uuidString },
            "visit_purpose": visitPurpose
        ]
    }
} 