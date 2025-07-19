//
//  mic_for_macApp.swift
//  mic-for-mac
//
//  Created by Reo Kosaka on 6/17/25.
//

import SwiftUI

@main
struct mic_for_macApp: App {
    @StateObject private var supabaseService = SupabaseService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
