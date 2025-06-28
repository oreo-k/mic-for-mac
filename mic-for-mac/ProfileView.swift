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
                
                // Medical Information
                GroupBox("Medical Information") {
                    VStack(spacing: 15) {
                        TextField("Special needs", text: $dogProfile.specialNeeds, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                        
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
                    }
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