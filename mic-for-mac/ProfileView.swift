import SwiftUI

struct ProfileView: View {
    @StateObject private var profileManager = ProfileManager()
    @State private var selectedTab = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab Picker
                Picker("Profile Type", selection: $selectedTab) {
                    Text("🐕 Dog Profile").tag(0)
                    Text("👤 Owner Profile").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    DogProfileEditView(dogProfile: $profileManager.dogProfile)
                        .tag(0)
                    
                    OwnerProfileEditView(ownerProfile: $profileManager.ownerProfile)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if selectedTab == 0 {
                            profileManager.saveDogProfile()
                        } else {
                            profileManager.saveOwnerProfile()
                        }
                    }
                }
            }
        }
    }
}

struct DogProfileEditView: View {
    @Binding var dogProfile: DogProfile
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Basic Information
                GroupBox("Basic Information") {
                    VStack(spacing: 15) {
                        HStack {
                            Text("Name:")
                            TextField("Dog's name", text: $dogProfile.name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("Breed:")
                            TextField("Breed", text: $dogProfile.breed)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date of Birth:")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            DatePicker(
                                "Date of Birth",
                                selection: $dogProfile.dateOfBirth,
                                displayedComponents: .date
                            )
                            .datePickerStyle(CompactDatePickerStyle())
                            .labelsHidden()
                            
                            HStack {
                                Text("Age:")
                                    .foregroundColor(.secondary)
                                Text(dogProfile.ageDescription)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        HStack {
                            Text("Weight:")
                            TextField("Weight", value: $dogProfile.weight, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text("lbs")
                        }
                        
                        HStack {
                            Text("Color:")
                            TextField("Color", text: $dogProfile.color)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("Microchip:")
                            TextField("Microchip number", text: $dogProfile.microchipNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                
                // Current Medical Details
                GroupBox("Current Medical Details") {
                    VStack(spacing: 15) {
                        Text("Current Medications:")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.headline)
                        
                        ForEach(dogProfile.currentMedications.indices, id: \.self) { index in
                            CurrentMedicationRow(medication: $dogProfile.currentMedications[index])
                            
                            Button("Remove Medication") {
                                dogProfile.currentMedications.remove(at: index)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        
                        Button("Add Current Medication") {
                            dogProfile.currentMedications.append(DogProfile.CurrentMedication())
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                // Medical History
                GroupBox("Medical History") {
                    VStack(spacing: 15) {
                        Text("Previous Diagnoses & Treatments:")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.headline)
                        
                        ForEach(dogProfile.medicalHistory.indices, id: \.self) { index in
                            MedicalHistoryRow(record: $dogProfile.medicalHistory[index])
                            
                            Button("Remove Record") {
                                dogProfile.medicalHistory.remove(at: index)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        
                        Button("Add Medical Record") {
                            dogProfile.medicalHistory.append(DogProfile.MedicalRecord(
                                date: Date(),
                                diagnosis: "",
                                treatment: "",
                                veterinarian: "",
                                notes: ""
                            ))
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                // Surgery History
                GroupBox("Surgery History") {
                    VStack(spacing: 15) {
                        Text("Previous Surgeries:")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.headline)
                        
                        ForEach(dogProfile.surgeries.indices, id: \.self) { index in
                            SurgeryRow(surgery: $dogProfile.surgeries[index])
                            
                            Button("Remove Surgery") {
                                dogProfile.surgeries.remove(at: index)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        
                        Button("Add Surgery Record") {
                            dogProfile.surgeries.append(DogProfile.SurgeryRecord(
                                date: Date(),
                                procedure: "",
                                surgeon: "",
                                hospital: "",
                                complications: "",
                                recoveryNotes: "",
                                followUpRequired: false,
                                followUpDate: nil
                            ))
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                // Vaccination Records
                GroupBox("Vaccination Records") {
                    VStack(spacing: 15) {
                        Text("Vaccinations:")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.headline)
                        
                        ForEach(dogProfile.vaccinations.indices, id: \.self) { index in
                            VaccinationRow(vaccination: $dogProfile.vaccinations[index])
                            
                            Button("Remove Vaccination") {
                                dogProfile.vaccinations.remove(at: index)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        
                        Button("Add Vaccination") {
                            dogProfile.vaccinations.append(DogProfile.VaccinationRecord(
                                date: Date(),
                                vaccineName: "",
                                administeredBy: "",
                                nextDueDate: nil,
                                notes: ""
                            ))
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                // Allergies
                GroupBox("Allergies") {
                    VStack(spacing: 15) {
                        Text("Allergies:")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ForEach(dogProfile.allergies.indices, id: \.self) { index in
                            HStack {
                                TextField("Allergy", text: $dogProfile.allergies[index])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Button("Remove") {
                                    dogProfile.allergies.remove(at: index)
                                }
                                .foregroundColor(.red)
                            }
                        }
                        
                        Button("Add Allergy") {
                            dogProfile.allergies.append("")
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                // Special Needs
                GroupBox("Special Needs") {
                    TextField("Special needs", text: $dogProfile.specialNeeds, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                // Notes
                GroupBox("Notes") {
                    TextField("Additional notes", text: $dogProfile.notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
            }
            .padding()
        }
    }
}

struct OwnerProfileEditView: View {
    @Binding var ownerProfile: OwnerProfile
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Basic Information
                GroupBox("Basic Information") {
                    VStack(spacing: 15) {
                        HStack {
                            Text("First Name:")
                            TextField("First name", text: $ownerProfile.firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("Last Name:")
                            TextField("Last name", text: $ownerProfile.lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("Email:")
                            TextField("Email", text: $ownerProfile.email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                        }
                        
                        HStack {
                            Text("Phone:")
                            TextField("Phone", text: $ownerProfile.phone)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                        }
                    }
                }
                
                // Address
                GroupBox("Address") {
                    VStack(spacing: 15) {
                        TextField("Street", text: $ownerProfile.address.street)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        HStack {
                            TextField("City", text: $ownerProfile.address.city)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("State", text: $ownerProfile.address.state)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            TextField("ZIP Code", text: $ownerProfile.address.zipCode)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Country", text: $ownerProfile.address.country)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                
                // Emergency Contact
                GroupBox("Emergency Contact") {
                    VStack(spacing: 15) {
                        HStack {
                            Text("Name:")
                            TextField("Emergency contact name", text: $ownerProfile.emergencyContact.name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("Relationship:")
                            TextField("Relationship", text: $ownerProfile.emergencyContact.relationship)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("Phone:")
                            TextField("Emergency phone", text: $ownerProfile.emergencyContact.phone)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                        }
                        
                        HStack {
                            Text("Email:")
                            TextField("Emergency email", text: $ownerProfile.emergencyContact.email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                        }
                    }
                }
                
                // Veterinary Preferences
                GroupBox("Veterinary Preferences") {
                    VStack(spacing: 15) {
                        HStack {
                            Text("Preferred Vet:")
                            TextField("Veterinarian name", text: $ownerProfile.preferredVeterinarian)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("Preferred Clinic:")
                            TextField("Clinic name", text: $ownerProfile.preferredClinic)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                
                // Notes
                GroupBox("Notes") {
                    TextField("Additional notes", text: $ownerProfile.notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
            }
            .padding()
        }
    }
}

// MARK: - Row Components
struct CurrentMedicationRow: View {
    @Binding var medication: DogProfile.CurrentMedication
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Medication")
                    .font(.headline)
                Spacer()
                Button(isExpanded ? "Hide" : "Show") {
                    isExpanded.toggle()
                }
                .foregroundColor(.blue)
            }
            
            if isExpanded {
                VStack(spacing: 8) {
                    HStack {
                        Text("Name:")
                        TextField("Medication name", text: $medication.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Dosage:")
                        TextField("e.g., 10mg", text: $medication.dosage)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Frequency:")
                        TextField("e.g., twice daily", text: $medication.frequency)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Start Date:")
                        DatePicker("Start Date", selection: $medication.startDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("End Date:")
                        DatePicker("End Date", selection: Binding(
                            get: { medication.endDate ?? Date() },
                            set: { medication.endDate = $0 }
                        ), displayedComponents: .date)
                        .labelsHidden()
                    }
                    
                    HStack {
                        Text("Prescribed By:")
                        TextField("Veterinarian name", text: $medication.prescribedBy)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    TextField("Instructions", text: $medication.instructions, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                    
                    TextField("Notes", text: $medication.notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
    }
}

struct MedicalHistoryRow: View {
    @Binding var record: DogProfile.MedicalRecord
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Medical Record")
                    .font(.headline)
                Spacer()
                Button(isExpanded ? "Hide" : "Show") {
                    isExpanded.toggle()
                }
                .foregroundColor(.blue)
            }
            
            if isExpanded {
                VStack(spacing: 8) {
                    HStack {
                        Text("Date:")
                        DatePicker("Date", selection: $record.date, displayedComponents: .date)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Diagnosis:")
                        TextField("Diagnosis", text: $record.diagnosis)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Treatment:")
                        TextField("Treatment", text: $record.treatment)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Veterinarian:")
                        TextField("Veterinarian name", text: $record.veterinarian)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    TextField("Notes", text: $record.notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
    }
}

struct SurgeryRow: View {
    @Binding var surgery: DogProfile.SurgeryRecord
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Surgery")
                    .font(.headline)
                Spacer()
                Button(isExpanded ? "Hide" : "Show") {
                    isExpanded.toggle()
                }
                .foregroundColor(.blue)
            }
            
            if isExpanded {
                VStack(spacing: 8) {
                    HStack {
                        Text("Date:")
                        DatePicker("Date", selection: $surgery.date, displayedComponents: .date)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Procedure:")
                        TextField("Surgical procedure", text: $surgery.procedure)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Surgeon:")
                        TextField("Surgeon name", text: $surgery.surgeon)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Hospital:")
                        TextField("Hospital name", text: $surgery.hospital)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    TextField("Complications", text: $surgery.complications, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                    
                    TextField("Recovery Notes", text: $surgery.recoveryNotes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                    
                    HStack {
                        Text("Follow-up Required:")
                        Toggle("", isOn: $surgery.followUpRequired)
                    }
                    
                    if surgery.followUpRequired {
                        HStack {
                            Text("Follow-up Date:")
                            DatePicker("Follow-up Date", selection: Binding(
                                get: { surgery.followUpDate ?? Date() },
                                set: { surgery.followUpDate = $0 }
                            ), displayedComponents: .date)
                            .labelsHidden()
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
    }
}

struct VaccinationRow: View {
    @Binding var vaccination: DogProfile.VaccinationRecord
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Vaccination")
                    .font(.headline)
                Spacer()
                Button(isExpanded ? "Hide" : "Show") {
                    isExpanded.toggle()
                }
                .foregroundColor(.blue)
            }
            
            if isExpanded {
                VStack(spacing: 8) {
                    HStack {
                        Text("Date:")
                        DatePicker("Date", selection: $vaccination.date, displayedComponents: .date)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Vaccine:")
                        TextField("Vaccine name", text: $vaccination.vaccineName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Administered By:")
                        TextField("Veterinarian name", text: $vaccination.administeredBy)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Next Due:")
                        DatePicker("Next Due Date", selection: Binding(
                            get: { vaccination.nextDueDate ?? Date() },
                            set: { vaccination.nextDueDate = $0 }
                        ), displayedComponents: .date)
                        .labelsHidden()
                    }
                    
                    TextField("Notes", text: $vaccination.notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
    }
} 