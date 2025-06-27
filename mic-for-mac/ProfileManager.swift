import Foundation

class ProfileManager: ObservableObject {
    @Published var dogProfile: DogProfile = DogProfile()
    @Published var ownerProfile: OwnerProfile = OwnerProfile()
    
    private let dogProfileKey = "dogProfile"
    private let ownerProfileKey = "ownerProfile"
    
    init() {
        loadProfiles()
    }
    
    func saveDogProfile() {
        if let encoded = try? JSONEncoder().encode(dogProfile) {
            UserDefaults.standard.set(encoded, forKey: dogProfileKey)
        }
    }
    
    func saveOwnerProfile() {
        if let encoded = try? JSONEncoder().encode(ownerProfile) {
            UserDefaults.standard.set(encoded, forKey: ownerProfileKey)
        }
    }
    
    private func loadProfiles() {
        if let dogData = UserDefaults.standard.data(forKey: dogProfileKey),
           let loadedDogProfile = try? JSONDecoder().decode(DogProfile.self, from: dogData) {
            self.dogProfile = loadedDogProfile
        }
        
        if let ownerData = UserDefaults.standard.data(forKey: ownerProfileKey),
           let loadedOwnerProfile = try? JSONDecoder().decode(OwnerProfile.self, from: ownerData) {
            self.ownerProfile = loadedOwnerProfile
        }
    }
    
    func resetProfiles() {
        dogProfile = DogProfile()
        ownerProfile = OwnerProfile()
        UserDefaults.standard.removeObject(forKey: dogProfileKey)
        UserDefaults.standard.removeObject(forKey: ownerProfileKey)
    }
} 