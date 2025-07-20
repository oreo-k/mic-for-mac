import Foundation
import Supabase
import Combine

// MARK: - File Options Helper
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
    private var realtimeChannel: RealtimeChannelV2?
    private var realtimeTasks: [Task<Void, Never>] = []
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var currentUser: Auth.User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Testing Properties
    // TEMPORARY: For testing without authentication - persistent test user ID
    private let persistentTestUserId = UUID() // Same user ID for all test data
    
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
        try await client
            .from(SupabaseConfig.Tables.userProfiles)
            .insert(profile)
            .execute()
    }
    
    func getUserProfile(userId: UUID) async throws -> UserProfile? {
        let response: [UserProfile] = try await client
            .from(SupabaseConfig.Tables.userProfiles)
            .select()
            .eq("id", value: userId)
            .execute()
            .value
        
        return response.first
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        try await client
            .from(SupabaseConfig.Tables.userProfiles)
            .update(profile)
            .eq("id", value: profile.id)
            .execute()
    }
    
    // Dog Profiles
    func createDogProfile(_ profile: DogProfile) async throws {
        print("🔧 SupabaseService: Creating dog profile...")
        print("  Dog: \(profile.name)")
        print("  Table: \(SupabaseConfig.Tables.dogProfiles)")
        print("  Is authenticated: \(isAuthenticated)")
        
        // TEMPORARY: For testing without authentication
        let testUserId = UUID() // Generate a test user ID
        
        // Check authentication (temporarily disabled for testing)
        // guard isAuthenticated, let currentUser = currentUser else {
        //     throw SupabaseError.notAuthenticated
        // }
        
        print("🧪 TESTING MODE: Using test user ID: \(testUserId)")
        
        do {
            // Convert DogProfile to proper Supabase format
            let supabaseData = SupabaseDogProfile(
                id: profile.id.uuidString,
                userId: testUserId.uuidString, // Use test user ID
                name: profile.name,
                breed: profile.breed,
                dateOfBirth: ISO8601DateFormatter().string(from: profile.dateOfBirth),
                weight: profile.weight,
                color: profile.color,
                microchipNumber: profile.microchipNumber,
                medicalConditions: profile.medicalHistory.map { "\($0.date): \($0.diagnosis)" },
                medications: profile.currentMedications.map { "\($0.name) - \($0.dosage)" },
                allergies: profile.allergies,
                specialNeeds: profile.specialNeeds,
                photoUrl: profile.photoURL,
                notes: profile.notes,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            let response = try await client
                .from(SupabaseConfig.Tables.dogProfiles)
                .insert(supabaseData)
                .execute()
            
            print("✅ Dog profile created successfully in Supabase")
            print("  Response: \(response)")
            
        } catch {
            print("❌ Failed to create dog profile in Supabase")
            print("  Error: \(error)")
            print("  Error type: \(type(of: error))")
            print("  Error description: \(error.localizedDescription)")
            
            throw error
        }
    }
    
    func getDogProfiles(userId: UUID) async throws -> [DogProfile] {
        let response: [DogProfile] = try await client
            .from(SupabaseConfig.Tables.dogProfiles)
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return response
    }
    
    func updateDogProfile(_ profile: DogProfile) async throws {
        try await client
            .from(SupabaseConfig.Tables.dogProfiles)
            .update(profile)
            .eq("id", value: profile.id)
            .execute()
    }
    
    func deleteDogProfile(id: UUID) async throws {
        try await client
            .from(SupabaseConfig.Tables.dogProfiles)
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // Owner Profiles
    func createOwnerProfile(_ profile: OwnerProfile) async throws {
        print("🔧 SupabaseService: Creating owner profile...")
        print("  Owner: \(profile.fullName)")
        print("  Table: \(SupabaseConfig.Tables.ownerProfiles)")
        print("  Is authenticated: \(isAuthenticated)")
        
        // TEMPORARY: For testing without authentication
        let testUserId = UUID() // Generate a test user ID
        
        // Check authentication (temporarily disabled for testing)
        // guard isAuthenticated, let currentUser = currentUser else {
        //     throw SupabaseError.notAuthenticated
        // }
        
        print("🧪 TESTING MODE: Using test user ID: \(testUserId)")
        
        do {
            // Convert OwnerProfile to proper Supabase format
            let supabaseData = SupabaseOwnerProfile(
                id: profile.id.uuidString,
                userId: testUserId.uuidString, // Use test user ID
                fullName: profile.fullName,
                phone: profile.phone,
                address: "\(profile.address.street), \(profile.address.city), \(profile.address.state) \(profile.address.zipCode)",
                emergencyContact: "\(profile.emergencyContact.name) - \(profile.emergencyContact.phone)",
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            let response = try await client
                .from(SupabaseConfig.Tables.ownerProfiles)
                .insert(supabaseData)
                .execute()
            
            print("✅ Owner profile created successfully in Supabase")
            print("  Response: \(response)")
            
        } catch {
            print("❌ Failed to create owner profile in Supabase")
            print("  Error: \(error)")
            print("  Error type: \(type(of: error))")
            print("  Error description: \(error.localizedDescription)")
            
            throw error
        }
    }
    
    func getOwnerProfiles(userId: UUID) async throws -> [OwnerProfile] {
        let response: [OwnerProfile] = try await client
            .from(SupabaseConfig.Tables.ownerProfiles)
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return response
    }
    
    func updateOwnerProfile(_ profile: OwnerProfile) async throws {
        try await client
            .from(SupabaseConfig.Tables.ownerProfiles)
            .update(profile)
            .eq("id", value: profile.id)
            .execute()
    }
    
    func deleteOwnerProfile(id: UUID) async throws {
        try await client
            .from(SupabaseConfig.Tables.ownerProfiles)
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // Audio Files
    func createAudioFile(_ audioFile: AudioFile) async throws {
        try await client
            .from(SupabaseConfig.Tables.audioFiles)
            .insert(audioFile)
            .execute()
    }
    
    func getAudioFiles(userId: UUID) async throws -> [AudioFile] {
        let response: [AudioFile] = try await client
            .from(SupabaseConfig.Tables.audioFiles)
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    func updateAudioFile(_ audioFile: AudioFile) async throws {
        try await client
            .from(SupabaseConfig.Tables.audioFiles)
            .update(audioFile)
            .eq("id", value: audioFile.id)
            .execute()
    }
    
    func deleteAudioFile(id: UUID) async throws {
        try await client
            .from(SupabaseConfig.Tables.audioFiles)
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - File Storage Operations
    
    func uploadAudioFile(_ fileURL: URL, fileName: String) async throws -> String {
        let fileData = try Data(contentsOf: fileURL)
        let response = try await client.storage
            .from(SupabaseConfig.Storage.audioFiles)
            .upload(
                fileName,
                data: fileData,
                options: Storage.FileOptions(contentType: "audio/m4a")
            )
        return response.path
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
        // Clean up any existing subscriptions first
        cleanupRealtimeSubscriptions()
        
        Task {
            let channel = client.realtimeV2.channel("audio_files")
            self.realtimeChannel = channel
            
            // Subscribe to postgres changes for audio_files table with separate action types
            let insertions = channel.postgresChange(InsertAction.self, table: "audio_files")
            let updates = channel.postgresChange(UpdateAction.self, table: "audio_files")
            let deletions = channel.postgresChange(DeleteAction.self, table: "audio_files")
            
            // Subscribe to the channel
            await channel.subscribe()
            
            // Handle insertions
            let insertionTask = Task {
                for await insertion in insertions {
                    await handleAudioFileInserted(insertion)
                }
            }
            realtimeTasks.append(insertionTask)
            
            // Handle updates
            let updateTask = Task {
                for await update in updates {
                    await handleAudioFileUpdated(update)
                }
            }
            realtimeTasks.append(updateTask)
            
            // Handle deletions
            let deletionTask = Task {
                for await deletion in deletions {
                    await handleAudioFileDeleted(deletion)
                }
            }
            realtimeTasks.append(deletionTask)
        }
    }
    
    private func handleAudioFileInserted(_ action: InsertAction) async {
        // Handle new audio file insertion
        print("Processing new audio file: \(action.record)")
        // TODO: Update UI or trigger refresh
        // You can decode the record here if needed:
        // let audioFile = try? action.decodeRecord(decoder: JSONDecoder()) as AudioFile
    }
    
    private func handleAudioFileUpdated(_ action: UpdateAction) async {
        // Handle audio file update
        print("Processing audio file update: \(action.record)")
        // TODO: Update UI or trigger refresh
        // You can decode the record here if needed:
        // let audioFile = try? action.decodeRecord(decoder: JSONDecoder()) as AudioFile
    }
    
    private func handleAudioFileDeleted(_ action: DeleteAction) async {
        // Handle audio file deletion
        print("Processing audio file deletion: \(action.oldRecord)")
        // TODO: Update UI or trigger refresh
        // You can decode the old record here if needed:
        // let audioFile = try? action.decodeOldRecord(decoder: JSONDecoder()) as AudioFile
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Cleanup
    
    func cleanupRealtimeSubscriptions() {
        // Cancel all real-time tasks
        for task in realtimeTasks {
            task.cancel()
        }
        realtimeTasks.removeAll()
        
        // Unsubscribe from the channel
        Task {
            await realtimeChannel?.unsubscribe()
            realtimeChannel = nil
        }
        
        print("Real-time subscriptions cleanup completed")
    }
    
    deinit {
        cleanupRealtimeSubscriptions()
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

// MARK: - Supabase Data Models (Encodable)
struct SupabaseDogProfile: Encodable {
    let id: String
    let userId: String
    let name: String
    let breed: String?
    let dateOfBirth: String?
    let weight: Double?
    let color: String?
    let microchipNumber: String?
    let medicalConditions: [String]?
    let medications: [String]?
    let allergies: [String]?
    let specialNeeds: String?
    let photoUrl: String?
    let notes: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case breed
        case dateOfBirth = "date_of_birth"
        case weight
        case color
        case microchipNumber = "microchip_number"
        case medicalConditions = "medical_conditions"
        case medications
        case allergies
        case specialNeeds = "special_needs"
        case photoUrl = "photo_url"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct SupabaseOwnerProfile: Encodable {
    let id: String
    let userId: String
    let fullName: String
    let phone: String?
    let address: String?
    let emergencyContact: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fullName = "full_name"
        case phone
        case address
        case emergencyContact = "emergency_contact"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
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
            "medical_conditions": [], // Will be populated from medicalHistory
            "medications": [], // Will be populated from currentMedications
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

extension OwnerProfile {
    var supabaseFormat: [String: Any] {
        return [
            "id": id.uuidString,
            "user_id": "", // Will be set by the service
            "full_name": fullName,
            "phone": phone,
            "address": "\(address.street), \(address.city), \(address.state) \(address.zipCode)",
            "emergency_contact": "\(emergencyContact.name) - \(emergencyContact.phone)",
            "created_at": Date(),
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

// MARK: - Error Types
enum SupabaseError: Error, LocalizedError {
    case notAuthenticated
    case configurationError
    case networkError
    case databaseError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated. Please sign in first."
        case .configurationError:
            return "Supabase configuration is invalid. Please check your settings."
        case .networkError:
            return "Network error occurred. Please check your internet connection."
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
} 