//
//  VeterinaryConsultationForm.swift
//  mic-for-mac
//
//  Created by Reo Kosaka on 6/30/25.
//

import SwiftUI

struct VeterinaryConsultationForm: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = ProfileManager()
    
    @State private var selectedDogs: Set<UUID> = []
    @State private var visitPurpose: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let onFormSubmitted: (Set<UUID>, String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "stethoscope")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Veterinary Consultation")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select which dog(s) will see the doctor and optionally describe the purpose of the visit.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Dog Selection Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Which dog(s) will see the doctor?")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if profileManager.multiDogProfile.dogs.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "pawprint.circle")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                            
                            Text("No dogs added to profile yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Please add dogs in the Profile section first")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(profileManager.multiDogProfile.dogs) { dog in
                                DogSelectionCard(
                                    dog: dog,
                                    isSelected: selectedDogs.contains(dog.id),
                                    onToggle: { isSelected in
                                        if isSelected {
                                            selectedDogs.insert(dog.id)
                                        } else {
                                            selectedDogs.remove(dog.id)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                
                // Visit Purpose Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Purpose of Visit (Optional)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Describe the reason for the veterinary visit. This helps provide more context for the conversation summary.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., Annual checkup, vaccination, health concern, follow-up appointment...", text: $visitPurpose, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: submitForm) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Continue to Recording")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(selectedDogs.isEmpty ? Color.gray : Color.blue)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(selectedDogs.isEmpty)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
        .alert("Form Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func submitForm() {
        guard !selectedDogs.isEmpty else {
            alertMessage = "Please select at least one dog for the veterinary consultation."
            showingAlert = true
            return
        }
        
        // Get the selected dog names for display
        let selectedDogNames = profileManager.multiDogProfile.dogs
            .filter { selectedDogs.contains($0.id) }
            .map { $0.displayName }
            .joined(separator: ", ")
        
        // Call the callback with selected dogs and visit purpose
        onFormSubmitted(selectedDogs, visitPurpose)
        
        // Dismiss the form
        dismiss()
    }
}

struct DogSelectionCard: View {
    let dog: DogProfile
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                }
                
                Image(systemName: "pawprint.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(dog.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                
                Text("Age: \(dog.ageDescription)")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VeterinaryConsultationForm_Previews: PreviewProvider {
    static var previews: some View {
        VeterinaryConsultationForm { selectedDogs, purpose in
            print("Selected dogs: \(selectedDogs)")
            print("Purpose: \(purpose)")
        }
    }
} 