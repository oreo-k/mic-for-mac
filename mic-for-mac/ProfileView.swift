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
                    Text("🐕 Dogs").tag(0)
                    Text("👥 Owners").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    MultiDogProfileView(multiDogProfile: $profileManager.multiDogProfile)
                        .tag(0)
                    
                    MultiOwnerProfileView(multiOwnerProfile: $profileManager.multiOwnerProfile)
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
                            profileManager.saveMultiDogProfile()
                        } else {
                            profileManager.saveMultiOwnerProfile()
                        }
                    }
                }
            }
        }
    }
}

struct MultiDogProfileView: View {
    @Binding var multiDogProfile: MultiDogProfile
    @State private var showingAddDog = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Dog Selector
                if !multiDogProfile.dogs.isEmpty {
                    GroupBox("Selected Dog") {
                        VStack(spacing: 15) {
                            if let selectedDog = multiDogProfile.selectedDog {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(selectedDog.displayName)
                                            .font(.headline)
                                        Text("Age: \(selectedDog.ageDescription)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button("Change") {
                                        // This will be handled by the dog selector
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                            
                            // Dog Selector Picker
                            if multiDogProfile.dogs.count > 1 {
                                Picker("Select Dog", selection: Binding(
                                    get: { multiDogProfile.selectedDogId ?? UUID() },
                                    set: { multiDogProfile.selectDog(withId: $0) }
                                )) {
                                    ForEach(multiDogProfile.dogs) { dog in
                                        Text(dog.displayName).tag(dog.id)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                        }
                    }
                }
                
                // Dogs List
                GroupBox("All Dogs") {
                    VStack(spacing: 15) {
                        if multiDogProfile.dogs.isEmpty {
                            Text("No dogs added yet")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(multiDogProfile.dogs.indices, id: \.self) { index in
                                DogRowView(
                                    dog: $multiDogProfile.dogs[index],
                                    isSelected: multiDogProfile.selectedDogId == multiDogProfile.dogs[index].id,
                                    onDelete: {
                                        multiDogProfile.removeDog(withId: multiDogProfile.dogs[index].id)
                                    },
                                    onSelect: {
                                        multiDogProfile.selectDog(withId: multiDogProfile.dogs[index].id)
                                    }
                                )
                            }
                        }
                        
                        Button("Add Dog") {
                            showingAddDog = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                // Selected Dog Details
                if let selectedDog = multiDogProfile.selectedDog {
                    DogDetailView(dog: Binding(
                        get: { selectedDog },
                        set: { updatedDog in
                            multiDogProfile.updateDog(updatedDog)
                        }
                    ))
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingAddDog) {
            AddDogView { newDog in
                multiDogProfile.addDog(newDog)
                showingAddDog = false
            }
        }
    }
}

struct DogRowView: View {
    @Binding var dog: DogProfile
    let isSelected: Bool
    let onDelete: () -> Void
    let onSelect: () -> Void
    @State private var isExpanded = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dog.displayName)
                        .font(.headline)
                    Text("Age: \(dog.ageDescription)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                Button(isExpanded ? "Hide" : "Edit") {
                    isExpanded.toggle()
                }
                .foregroundColor(.blue)
                
                if !isSelected {
                    Button("Select") {
                        onSelect()
                    }
                    .foregroundColor(.green)
                }
                
                Button("Delete") {
                    showingDeleteAlert = true
                }
                .foregroundColor(.red)
            }
            
            if isExpanded {
                DogDetailView(dog: $dog)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
        )
        .alert("Delete Dog", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(dog.displayName)'? This action cannot be undone.")
        }
    }
}

struct DogDetailView: View {
    @Binding var dog: DogProfile
    
    var body: some View {
        VStack(spacing: 15) {
            // Basic Information
            GroupBox("Basic Information") {
                VStack(spacing: 15) {
                    HStack {
                        Text("Name:")
                        TextField("Dog's name", text: $dog.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Breed:")
                        TextField("Breed", text: $dog.breed)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date of Birth:")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        DatePicker(
                            "Date of Birth",
                            selection: $dog.dateOfBirth,
                            displayedComponents: .date
                        )
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        
                        HStack {
                            Text("Age:")
                                .foregroundColor(.secondary)
                            Text(dog.ageDescription)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack {
                        Text("Weight:")
                        TextField("Weight", value: $dog.weight, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("lbs")
                    }
                    
                    HStack {
                        Text("Color:")
                        TextField("Color", text: $dog.color)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Microchip:")
                        TextField("Microchip number", text: $dog.microchipNumber)
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
                    
                    ForEach(dog.currentMedications.indices, id: \.self) { index in
                        CurrentMedicationRow(medication: $dog.currentMedications[index])
                        
                        DeleteButton(
                            title: "Remove Medication",
                            itemName: dog.currentMedications[index].name.isEmpty ? "this medication" : dog.currentMedications[index].name
                        ) {
                            dog.currentMedications.remove(at: index)
                        }
                    }
                    
                    Button("Add Current Medication") {
                        dog.currentMedications.append(DogProfile.CurrentMedication())
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
                    
                    ForEach(dog.medicalHistory.indices, id: \.self) { index in
                        MedicalHistoryRow(record: $dog.medicalHistory[index])
                        
                        DeleteButton(
                            title: "Remove Record",
                            itemName: dog.medicalHistory[index].diagnosis.isEmpty ? "this medical record" : dog.medicalHistory[index].diagnosis
                        ) {
                            dog.medicalHistory.remove(at: index)
                        }
                    }
                    
                    Button("Add Medical Record") {
                        dog.medicalHistory.append(DogProfile.MedicalRecord(
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
                    
                    ForEach(dog.surgeries.indices, id: \.self) { index in
                        SurgeryRow(surgery: $dog.surgeries[index])
                        
                        DeleteButton(
                            title: "Remove Surgery",
                            itemName: dog.surgeries[index].procedure.isEmpty ? "this surgery record" : dog.surgeries[index].procedure
                        ) {
                            dog.surgeries.remove(at: index)
                        }
                    }
                    
                    Button("Add Surgery Record") {
                        dog.surgeries.append(DogProfile.SurgeryRecord(
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
                    
                    ForEach(dog.vaccinations.indices, id: \.self) { index in
                        VaccinationRow(vaccination: $dog.vaccinations[index])
                        
                        DeleteButton(
                            title: "Remove Vaccination",
                            itemName: dog.vaccinations[index].vaccineName.isEmpty ? "this vaccination record" : dog.vaccinations[index].vaccineName
                        ) {
                            dog.vaccinations.remove(at: index)
                        }
                    }
                    
                    Button("Add Vaccination") {
                        dog.vaccinations.append(DogProfile.VaccinationRecord(
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
                    
                    ForEach(dog.allergies.indices, id: \.self) { index in
                        HStack {
                            TextField("Allergy", text: $dog.allergies[index])
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            DeleteButton(
                                title: "Remove",
                                itemName: dog.allergies[index].isEmpty ? "this allergy" : dog.allergies[index]
                            ) {
                                dog.allergies.remove(at: index)
                            }
                        }
                    }
                    
                    Button("Add Allergy") {
                        dog.allergies.append("")
                    }
                    .foregroundColor(.blue)
                }
            }
            
            // Special Needs
            GroupBox("Special Needs") {
                TextField("Special needs", text: $dog.specialNeeds, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
            
            // Notes
            GroupBox("Notes") {
                TextField("Additional notes", text: $dog.notes, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
        }
    }
}

struct AddDogView: View {
    @State private var newDog = DogProfile()
    @Environment(\.dismiss) private var dismiss
    let onAdd: (DogProfile) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Add New Dog")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    DogDetailView(dog: $newDog)
                        .padding()
                }
            }
            .navigationTitle("Add Dog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd(newDog)
                    }
                    .disabled(newDog.name.isEmpty)
                }
            }
        }
    }
}

struct MultiOwnerProfileView: View {
    @Binding var multiOwnerProfile: MultiOwnerProfile
    @State private var showingAddOwner = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Owners List
                GroupBox("Dog Owners") {
                    VStack(spacing: 15) {
                        if multiOwnerProfile.owners.isEmpty {
                            Text("No owners added yet")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(multiOwnerProfile.owners.indices, id: \.self) { index in
                                OwnerRowView(
                                    owner: $multiOwnerProfile.owners[index],
                                    onDelete: {
                                        multiOwnerProfile.removeOwner(withId: multiOwnerProfile.owners[index].id)
                                    }
                                )
                            }
                        }
                        
                        Button("Add Owner") {
                            showingAddOwner = true
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingAddOwner) {
            AddOwnerView { newOwner in
                multiOwnerProfile.addOwner(newOwner)
                showingAddOwner = false
            }
        }
    }
}

struct OwnerRowView: View {
    @Binding var owner: OwnerProfile
    let onDelete: () -> Void
    @State private var isExpanded = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(owner.displayName)
                        .font(.headline)
                    if !owner.phone.isEmpty || !owner.email.isEmpty {
                        Text("\(owner.phone.isEmpty ? "" : owner.phone)\(owner.phone.isEmpty || owner.email.isEmpty ? "" : " • ")\(owner.email.isEmpty ? "" : owner.email)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(isExpanded ? "Hide" : "Edit") {
                    isExpanded.toggle()
                }
                .foregroundColor(.blue)
                
                Button("Delete") {
                    showingDeleteAlert = true
                }
                .foregroundColor(.red)
            }
            
            if isExpanded {
                OwnerDetailView(owner: $owner)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
        .alert("Delete Owner", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(owner.displayName)'? This action cannot be undone.")
        }
    }
}

struct OwnerDetailView: View {
    @Binding var owner: OwnerProfile
    
    var body: some View {
        VStack(spacing: 15) {
            // Basic Information
            GroupBox("Basic Information") {
                VStack(spacing: 15) {
                    HStack {
                        Text("First Name:")
                        TextField("First name", text: $owner.firstName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Last Name:")
                        TextField("Last name", text: $owner.lastName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Relationship:")
                        TextField("e.g., Primary Owner, Spouse", text: $owner.relationship)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Email:")
                        TextField("Email", text: $owner.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                    }
                    
                    HStack {
                        Text("Phone:")
                        TextField("Phone", text: $owner.phone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                    }
                }
            }
            
            // Address
            GroupBox("Address") {
                VStack(spacing: 15) {
                    TextField("Street", text: $owner.address.street)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        TextField("City", text: $owner.address.city)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("State", text: $owner.address.state)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        TextField("ZIP Code", text: $owner.address.zipCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Country", text: $owner.address.country)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
            
            // Emergency Contact
            GroupBox("Emergency Contact") {
                VStack(spacing: 15) {
                    HStack {
                        Text("Name:")
                        TextField("Emergency contact name", text: $owner.emergencyContact.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Relationship:")
                        TextField("Relationship", text: $owner.emergencyContact.relationship)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Phone:")
                        TextField("Emergency phone", text: $owner.emergencyContact.phone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                    }
                    
                    HStack {
                        Text("Email:")
                        TextField("Emergency email", text: $owner.emergencyContact.email)
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
                        TextField("Veterinarian name", text: $owner.preferredVeterinarian)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Preferred Clinic:")
                        TextField("Clinic name", text: $owner.preferredClinic)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
            
            // Notes
            GroupBox("Notes") {
                TextField("Additional notes", text: $owner.notes, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
        }
    }
}

struct AddOwnerView: View {
    @State private var newOwner = OwnerProfile()
    @Environment(\.dismiss) private var dismiss
    let onAdd: (OwnerProfile) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Add New Owner")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    OwnerDetailView(owner: $newOwner)
                        .padding()
                }
            }
            .navigationTitle("Add Owner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd(newOwner)
                    }
                    .disabled(newOwner.firstName.isEmpty && newOwner.lastName.isEmpty)
                }
            }
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
                        Text("Active:")
                        Toggle("", isOn: $medication.isActive)
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

struct DeleteButton: View {
    let title: String
    let itemName: String
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Button(title) {
            showingDeleteAlert = true
        }
        .foregroundColor(.red)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .alert("Delete Item", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(itemName)'? This action cannot be undone.")
        }
    }
} 