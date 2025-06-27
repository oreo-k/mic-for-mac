import Foundation

struct DogProfile: Codable, Identifiable {
    var id = UUID()
    var name: String = ""
    var breed: String = ""
    var age: Int = 0
    var weight: Double = 0.0
    var color: String = ""
    var microchipNumber: String = ""
    var medicalHistory: [MedicalRecord] = []
    var medications: [Medication] = []
    var allergies: [String] = []
    var specialNeeds: String = ""
    var photoURL: String = ""
    var notes: String = ""
    
    struct MedicalRecord: Codable, Identifiable {
        var id = UUID()
        var date: Date
        var diagnosis: String
        var treatment: String
        var veterinarian: String
        var notes: String
    }
    
    struct Medication: Codable, Identifiable {
        var id = UUID()
        var name: String
        var dosage: String
        var frequency: String
        var startDate: Date
        var endDate: Date?
        var notes: String
    }
} 