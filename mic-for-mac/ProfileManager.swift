import Foundation

class ProfileManager: ObservableObject {
    @Published var dogProfile: DogProfile = DogProfile()
    @Published var multiOwnerProfile: MultiOwnerProfile = MultiOwnerProfile()
    
    private let dogProfileKey = "dogProfile"
    private let multiOwnerProfileKey = "multiOwnerProfile"
    
    init() {
        loadProfiles()
    }
    
    func saveDogProfile() {
        if let encoded = try? JSONEncoder().encode(dogProfile) {
            UserDefaults.standard.set(encoded, forKey: dogProfileKey)
        }
    }
    
    func saveMultiOwnerProfile() {
        if let encoded = try? JSONEncoder().encode(multiOwnerProfile) {
            UserDefaults.standard.set(encoded, forKey: multiOwnerProfileKey)
        }
    }
    
    private func loadProfiles() {
        if let dogData = UserDefaults.standard.data(forKey: dogProfileKey),
           let loadedDogProfile = try? JSONDecoder().decode(DogProfile.self, from: dogData) {
            self.dogProfile = loadedDogProfile
        }
        
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
        dogProfile = DogProfile()
        multiOwnerProfile = MultiOwnerProfile()
        UserDefaults.standard.removeObject(forKey: dogProfileKey)
        UserDefaults.standard.removeObject(forKey: multiOwnerProfileKey)
        UserDefaults.standard.removeObject(forKey: "ownerProfile") // Clean up old data
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