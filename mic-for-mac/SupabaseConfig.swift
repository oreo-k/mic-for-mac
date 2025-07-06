import Foundation
import Supabase

class SupabaseConfig {
    static let shared = SupabaseConfig()
    
    // MARK: - Configuration
    private var supabaseURL: String {
        // Try to get from environment variable first
        if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] {
            return envURL
        }
        // Fallback to UserDefaults (for development)
        return UserDefaults.standard.string(forKey: "SUPABASE_URL") ?? ""
    }
    
    private var supabaseAnonKey: String {
        // Try to get from environment variable first
        if let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
            return envKey
        }
        // Fallback to UserDefaults (for development)
        return UserDefaults.standard.string(forKey: "SUPABASE_ANON_KEY") ?? ""
    }
    
    // MARK: - Supabase Client
    lazy var client: SupabaseClient = {
        guard !supabaseURL.isEmpty, !supabaseAnonKey.isEmpty else {
            fatalError("Supabase configuration is missing. Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables or add them in UserDefaults.")
        }
        
        return SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseAnonKey
        )
    }()
    
    // MARK: - Database Tables
    struct Tables {
        static let consultations = "consultations"
        static let veterinaryContexts = "veterinary_contexts"
        static let userProfiles = "user_profiles"
        static let audioFiles = "audio_files"
        static let dogProfiles = "dog_profiles"
        static let ownerProfiles = "owner_profiles"
    }
    
    // MARK: - Storage Buckets
    struct Storage {
        static let audioFiles = "audio-files"
        static let avatars = "avatars"
    }
    
    // MARK: - Configuration Validation
    var isConfigured: Bool {
        return !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty
    }
    
    // MARK: - Error Types
    enum ConfigError: Error, LocalizedError {
        case missingURL
        case missingAnonKey
        case invalidURL
        
        var errorDescription: String? {
            switch self {
            case .missingURL:
                return "Supabase URL is missing. Please set SUPABASE_URL environment variable or add it in UserDefaults."
            case .missingAnonKey:
                return "Supabase anonymous key is missing. Please set SUPABASE_ANON_KEY environment variable or add it in UserDefaults."
            case .invalidURL:
                return "Invalid Supabase URL format."
            }
        }
    }
    
    // MARK: - Configuration Setup
    func validateConfiguration() throws {
        guard !supabaseURL.isEmpty else {
            throw ConfigError.missingURL
        }
        
        guard !supabaseAnonKey.isEmpty else {
            throw ConfigError.missingAnonKey
        }
        
        guard URL(string: supabaseURL) != nil else {
            throw ConfigError.invalidURL
        }
    }
    
    // MARK: - Development Helpers
    func setDevelopmentCredentials(url: String, anonKey: String) {
        UserDefaults.standard.set(url, forKey: "SUPABASE_URL")
        UserDefaults.standard.set(anonKey, forKey: "SUPABASE_ANON_KEY")
    }
    
    func clearDevelopmentCredentials() {
        UserDefaults.standard.removeObject(forKey: "SUPABASE_URL")
        UserDefaults.standard.removeObject(forKey: "SUPABASE_ANON_KEY")
    }
} 