//
//  VeterinaryContext.swift
//  mic-for-mac
//
//  Created by Reo Kosaka on 6/30/25.
//

import Foundation

struct VeterinaryContext: Codable {
    let selectedDogs: Set<UUID>
    let visitPurpose: String
    
    init(selectedDogs: Set<UUID>, visitPurpose: String) {
        self.selectedDogs = selectedDogs
        self.visitPurpose = visitPurpose
    }
    
    var hasVisitPurpose: Bool {
        !visitPurpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var selectedDogsDescription: String {
        if selectedDogs.isEmpty {
            return "No dogs selected"
        }
        return "Selected dogs: \(selectedDogs.count) dog(s)"
    }
    
    var fullDescription: String {
        var description = selectedDogsDescription
        if hasVisitPurpose {
            description += "\nPurpose: \(visitPurpose)"
        }
        return description
    }
} 