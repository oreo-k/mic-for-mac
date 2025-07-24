import Foundation

class ProfileManager: ObservableObject {
    @Published var multiDogProfile: MultiDogProfile = MultiDogProfile()
    @Published var multiOwnerProfile: MultiOwnerProfile = MultiOwnerProfile()
    
    private let multiDogProfileKey = "multiDogProfile"
    private let multiOwnerProfileKey = "multiOwnerProfile"
    private var supabaseService: SupabaseService? {
        // Only access SupabaseService if configuration is available
        guard SupabaseConfig.shared.isConfigured else {
            return nil
        }
        return SupabaseService.shared
    }
    
    init() {
        loadProfiles()
    }
    
    func saveMultiDogProfile() {
        print("💾 Saving dog profiles...")
        print("📊 Current dogs count: \(multiDogProfile.dogs.count)")
        
        // Save to UserDefaults (local storage)
        if let encoded = try? JSONEncoder().encode(multiDogProfile) {
            UserDefaults.standard.set(encoded, forKey: multiDogProfileKey)
            UserDefaults.standard.synchronize() // Force immediate save
            print("✅ Dog profiles saved to UserDefaults")
        } else {
            print("❌ Failed to encode dog profiles for UserDefaults")
        }
        
        // Save to Supabase
        Task {
            await saveDogsToSupabase()
        }
    }
    
    func saveMultiOwnerProfile() {
        // Save to UserDefaults (local storage)
        if let encoded = try? JSONEncoder().encode(multiOwnerProfile) {
            UserDefaults.standard.set(encoded, forKey: multiOwnerProfileKey)
        }
        
        // Save to Supabase
        Task {
            await saveOwnersToSupabase()
        }
    }
    
    private func saveDogsToSupabase() async {
        guard let supabaseService = supabaseService else {
            print("⚠️ Supabase not configured - saving to local storage only")
            return
        }
        
        // Check authentication
        guard supabaseService.isAuthenticated,
              let currentUser = supabaseService.currentUser else {
            print("⚠️ Not authenticated with Supabase - cannot save dogs")
            print("  Please sign in to your account to sync with Supabase")
            return
        }
        
        print("✅ Saving dogs to Supabase with authenticated user: \(currentUser.email ?? "Unknown")")
        
        do {
            // Save each dog profile to Supabase
            for dog in multiDogProfile.dogs {
                try await supabaseService.createDogProfile(dog)
                print("✅ Dog '\(dog.name)' saved to Supabase")
            }
        } catch {
            print("❌ Error saving dogs to Supabase: \(error)")
            if let supabaseError = error as? SupabaseError {
                print("  Supabase error: \(supabaseError.localizedDescription)")
            }
        }
    }
    
    private func saveOwnersToSupabase() async {
        guard let supabaseService = supabaseService else {
            print("⚠️ Supabase not configured - saving to local storage only")
            return
        }
        
        // Check authentication
        guard supabaseService.isAuthenticated,
              let currentUser = supabaseService.currentUser else {
            print("⚠️ Not authenticated with Supabase - cannot save owners")
            print("  Please sign in to your account to sync with Supabase")
            return
        }
        
        print("✅ Saving owners to Supabase with authenticated user: \(currentUser.email ?? "Unknown")")
        
        do {
            // Save each owner profile to Supabase
            for owner in multiOwnerProfile.owners {
                try await supabaseService.createOwnerProfile(owner)
                print("✅ Owner '\(owner.fullName)' saved to Supabase")
            }
        } catch {
            print("❌ Error saving owners to Supabase: \(error)")
            if let supabaseError = error as? SupabaseError {
                print("  Supabase error: \(supabaseError.localizedDescription)")
            }
        }
    }
    
    private func loadProfiles() {
        print("🔄 Loading profiles from UserDefaults...")
        
        // Load multi-dog profile
        if let dogData = UserDefaults.standard.data(forKey: multiDogProfileKey),
           let loadedMultiDogProfile = try? JSONDecoder().decode(MultiDogProfile.self, from: dogData) {
            self.multiDogProfile = loadedMultiDogProfile
            print("✅ Loaded \(loadedMultiDogProfile.dogs.count) dogs from UserDefaults")
        } else {
            print("⚠️ No dog profiles found in UserDefaults")
            // Migration: If no multi-dog profile exists, try to load the old single dog profile
            if let oldDogData = UserDefaults.standard.data(forKey: "dogProfile"),
               let oldDogProfile = try? JSONDecoder().decode(DogProfile.self, from: oldDogData) {
                print("🔄 Migrating old single dog profile...")
                // Convert old single dog to multi-dog format
                self.multiDogProfile = MultiDogProfile()
                self.multiDogProfile.addDog(oldDogProfile)
                saveMultiDogProfile()
                
                // Remove old profile data
                UserDefaults.standard.removeObject(forKey: "dogProfile")
            }
        }
        
        // Load multi-owner profile
        if let ownerData = UserDefaults.standard.data(forKey: multiOwnerProfileKey),
           let loadedMultiOwnerProfile = try? JSONDecoder().decode(MultiOwnerProfile.self, from: ownerData) {
            self.multiOwnerProfile = loadedMultiOwnerProfile
        } else {
            // Migration: If no multi-owner profile exists, try to load the old single owner profile
            if let oldOwnerData = UserDefaults.standard.data(forKey: "ownerProfile"),
               let oldOwnerProfile = try? JSONDecoder().decode(OwnerProfile.self, from: oldOwnerData) {
                // Convert old single owner to multi-owner format
                self.multiOwnerProfile = MultiOwnerProfile()
                self.multiOwnerProfile.addOwner(oldOwnerProfile)
                saveMultiOwnerProfile()
                
                // Remove old profile data
                UserDefaults.standard.removeObject(forKey: "ownerProfile")
            }
        }
    }
    
    func resetProfiles() {
        multiDogProfile = MultiDogProfile()
        multiOwnerProfile = MultiOwnerProfile()
        UserDefaults.standard.removeObject(forKey: multiDogProfileKey)
        UserDefaults.standard.removeObject(forKey: multiOwnerProfileKey)
        UserDefaults.standard.removeObject(forKey: "dogProfile") // Clean up old data
        UserDefaults.standard.removeObject(forKey: "ownerProfile") // Clean up old data
    }
    
    // Convenience method to get the selected dog (for backward compatibility)
    var selectedDog: DogProfile? {
        return multiDogProfile.selectedDog
    }
    
    // Convenience method to get all dogs
    var allDogs: [DogProfile] {
        return multiDogProfile.dogs
    }
    
    // Convenience method to get the primary owner (for backward compatibility)
    var primaryOwner: OwnerProfile? {
        return multiOwnerProfile.primaryOwner
    }
    
    // Convenience method to get all owners
    var allOwners: [OwnerProfile] {
        return multiOwnerProfile.owners
    }
} 