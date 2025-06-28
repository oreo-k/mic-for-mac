import Foundation

struct DogProfile: Codable, Identifiable {
    var id = UUID()
    var name: String = ""
    var breed: String = ""
    var dateOfBirth: Date = Date()
    var weight: Double = 0.0
    var color: String = ""
    var microchipNumber: String = ""
    var medicalHistory: [MedicalRecord] = []
    var medications: [Medication] = []
    var allergies: [String] = []
    var specialNeeds: String = ""
    var photoURL: String = ""
    var notes: String = ""
    
    // Computed property to calculate age
    var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year ?? 0
    }
    
    // Computed property to get age in years and months
    var ageDescription: String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year, .month], from: dateOfBirth, to: Date())
        
        let years = ageComponents.year ?? 0
        let months = ageComponents.month ?? 0
        
        if years == 0 {
            return "\(months) month\(months == 1 ? "" : "s")"
        } else if months == 0 {
            return "\(years) year\(years == 1 ? "" : "s")"
        } else {
            return "\(years) year\(years == 1 ? "" : "s"), \(months) month\(months == 1 ? "" : "s")"
        }
    }
    
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