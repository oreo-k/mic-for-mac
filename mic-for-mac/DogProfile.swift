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
    var currentMedications: [CurrentMedication] = []
    var surgeries: [SurgeryRecord] = []
    var vaccinations: [VaccinationRecord] = []
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
    
    // Computed property for display name with breed
    var displayName: String {
        if name.isEmpty {
            return "Unnamed Dog"
        }
        if breed.isEmpty {
            return name
        }
        return "\(name) (\(breed))"
    }
    
    // Historical medical records
    struct MedicalRecord: Codable, Identifiable {
        var id = UUID()
        var date: Date
        var diagnosis: String
        var treatment: String
        var veterinarian: String
        var notes: String
    }
    
    // Current medications being taken
    struct CurrentMedication: Codable, Identifiable {
        var id = UUID()
        var name: String
        var dosage: String
        var frequency: String
        var startDate: Date
        var endDate: Date?
        var isActive: Bool = true
        var instructions: String
        var prescribedBy: String
        var notes: String
        
        init(name: String = "", dosage: String = "", frequency: String = "", startDate: Date = Date(), endDate: Date? = nil, isActive: Bool = true, instructions: String = "", prescribedBy: String = "", notes: String = "") {
            self.name = name
            self.dosage = dosage
            self.frequency = frequency
            self.startDate = startDate
            self.endDate = endDate
            self.isActive = isActive
            self.instructions = instructions
            self.prescribedBy = prescribedBy
            self.notes = notes
        }
    }
    
    // Historical medications (for reference)
    struct Medication: Codable, Identifiable {
        var id = UUID()
        var name: String
        var dosage: String
        var frequency: String
        var startDate: Date
        var endDate: Date?
        var notes: String
    }
    
    // Surgery records
    struct SurgeryRecord: Codable, Identifiable {
        var id = UUID()
        var date: Date
        var procedure: String
        var surgeon: String
        var hospital: String
        var complications: String
        var recoveryNotes: String
        var followUpRequired: Bool
        var followUpDate: Date?
    }
    
    // Vaccination records
    struct VaccinationRecord: Codable, Identifiable {
        var id = UUID()
        var date: Date
        var vaccineName: String
        var administeredBy: String
        var nextDueDate: Date?
        var notes: String
    }
}

// New structure to manage multiple dogs
struct MultiDogProfile: Codable {
    var dogs: [DogProfile] = []
    var selectedDogId: UUID?
    
    // Computed property to get selected dog
    var selectedDog: DogProfile? {
        if let selectedId = selectedDogId {
            return dogs.first { $0.id == selectedId }
        }
        return dogs.first
    }
    
    // Computed property to get all dog names
    var allDogNames: String {
        return dogs.map { $0.name.isEmpty ? "Unnamed Dog" : $0.name }.joined(separator: ", ")
    }
    
    // Computed property to get all dog display names
    var allDogDisplayNames: String {
        return dogs.map { $0.displayName }.joined(separator: ", ")
    }
    
    // Add a new dog
    mutating func addDog(_ dog: DogProfile) {
        dogs.append(dog)
        if selectedDogId == nil {
            selectedDogId = dog.id
        }
    }
    
    // Remove a dog by ID
    mutating func removeDog(withId id: UUID) {
        dogs.removeAll { $0.id == id }
        
        // If we removed the selected dog, select the first available dog
        if selectedDogId == id {
            selectedDogId = dogs.first?.id
        }
    }
    
    // Update a dog
    mutating func updateDog(_ updatedDog: DogProfile) {
        if let index = dogs.firstIndex(where: { $0.id == updatedDog.id }) {
            dogs[index] = updatedDog
        }
    }
    
    // Select a dog
    mutating func selectDog(withId id: UUID) {
        if dogs.contains(where: { $0.id == id }) {
            selectedDogId = id
        }
    }
}