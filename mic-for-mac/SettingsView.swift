import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("OpenAI API Configuration")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.headline)
                        SecureField("Enter your OpenAI API key", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Your API key is stored locally and never shared.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Instructions")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Get your API key from OpenAI Platform")
                        Text("2. Paste it in the field above")
                        Text("3. The key will be stored securely on your device")
                        Text("4. Your key starts with 'sk-'")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Section {
                    Button("Save API Key") {
                        saveAPIKey()
                    }
                    .disabled(apiKey.isEmpty)
                    
                    Button("Clear API Key") {
                        clearAPIKey()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Settings", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadAPIKey()
            }
        }
    }
    
    private func saveAPIKey() {
        guard !apiKey.isEmpty else { return }
        
        // Basic validation - API key should start with "sk-"
        guard apiKey.hasPrefix("sk-") else {
            alertMessage = "Invalid API key format. OpenAI API keys start with 'sk-'"
            showingAlert = true
            return
        }
        
        UserDefaults.standard.set(apiKey, forKey: "OPENAI_API_KEY")
        alertMessage = "API key saved successfully!"
        showingAlert = true
    }
    
    private func clearAPIKey() {
        UserDefaults.standard.removeObject(forKey: "OPENAI_API_KEY")
        apiKey = ""
        alertMessage = "API key cleared successfully!"
        showingAlert = true
    }
    
    private func loadAPIKey() {
        if let savedKey = UserDefaults.standard.string(forKey: "OPENAI_API_KEY") {
            apiKey = savedKey
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 