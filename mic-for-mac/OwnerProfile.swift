import Foundation

struct OwnerProfile: Codable, Identifiable {
    var id = UUID()
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var phone: String = ""
    var address: Address = Address()
    var emergencyContact: EmergencyContact = EmergencyContact()
    var preferredVeterinarian: String = ""
    var preferredClinic: String = ""
    var notes: String = ""
    
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