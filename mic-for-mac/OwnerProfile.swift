import Foundation

struct OwnerProfile: Codable, Identifiable {
    var id = UUID()
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var phone: String = ""
    var relationship: String = "" // e.g., "Primary Owner", "Co-owner", "Spouse", "Family Member"
    var address: Address = Address()
    var emergencyContact: EmergencyContact = EmergencyContact()
    var preferredVeterinarian: String = ""
    var preferredClinic: String = ""
    var notes: String = ""
    
    // Computed property for full name
    var fullName: String {
        let first = firstName.trimmingCharacters(in: .whitespaces)
        let last = lastName.trimmingCharacters(in: .whitespaces)
        if first.isEmpty && last.isEmpty {
            return "Unnamed Owner"
        }
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
    
    // Computed property for display name with relationship
    var displayName: String {
        if relationship.isEmpty {
            return fullName
        }
        return "\(fullName) (\(relationship))"
    }
    
    struct Address: Codable {
        var street: String = ""
        var city: String = ""
        var state: String = ""
        var zipCode: String = ""
        var country: String = ""
    }
    
    struct EmergencyContact: Codable {
        var name: String = ""
        var relationship: String = ""
        var phone: String = ""
        var email: String = ""
    }
}

// New structure to manage multiple owners
struct MultiOwnerProfile: Codable {
    var owners: [OwnerProfile] = []
    
    // Computed property to get primary owner
    var primaryOwner: OwnerProfile? {
        return owners.first { $0.relationship.lowercased().contains("primary") || $0.relationship.isEmpty }
    }
    
    // Computed property to get all owner names
    var allOwnerNames: String {
        return owners.map { $0.fullName }.joined(separator: ", ")
    }
    
    // Computed property to get all owner display names
    var allOwnerDisplayNames: String {
        return owners.map { $0.displayName }.joined(separator: ", ")
    }
    
    // Add a new owner
    mutating func addOwner(_ owner: OwnerProfile) {
        owners.append(owner)
    }
    
    // Remove an owner by ID
    mutating func removeOwner(withId id: UUID) {
        owners.removeAll { $0.id == id }
    }
    
    // Update an owner
    mutating func updateOwner(_ updatedOwner: OwnerProfile) {
        if let index = owners.firstIndex(where: { $0.id == updatedOwner.id }) {
            owners[index] = updatedOwner
        }
    }
} 