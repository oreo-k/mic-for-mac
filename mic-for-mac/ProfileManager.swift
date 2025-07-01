import Foundation

class ProfileManager: ObservableObject {
    @Published var multiDogProfile: MultiDogProfile = MultiDogProfile()
    @Published var multiOwnerProfile: MultiOwnerProfile = MultiOwnerProfile()
    
    private let multiDogProfileKey = "multiDogProfile"
    private let multiOwnerProfileKey = "multiOwnerProfile"
    
    init() {
        loadProfiles()
    }
    
    func saveMultiDogProfile() {
        if let encoded = try? JSONEncoder().encode(multiDogProfile) {
            UserDefaults.standard.set(encoded, forKey: multiDogProfileKey)
        }
    }
    
    func saveMultiOwnerProfile() {
        if let encoded = try? JSONEncoder().encode(multiOwnerProfile) {
            UserDefaults.standard.set(encoded, forKey: multiOwnerProfileKey)
        }
    }
    
    private func loadProfiles() {
        // Load multi-dog profile
        if let dogData = UserDefaults.standard.data(forKey: multiDogProfileKey),
           let loadedMultiDogProfile = try? JSONDecoder().decode(MultiDogProfile.self, from: dogData) {
            self.multiDogProfile = loadedMultiDogProfile
        } else {
            // Migration: If no multi-dog profile exists, try to load the old single dog profile
            if let oldDogData = UserDefaults.standard.data(forKey: "dogProfile"),
               let oldDogProfile = try? JSONDecoder().decode(DogProfile.self, from: oldDogData) {
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