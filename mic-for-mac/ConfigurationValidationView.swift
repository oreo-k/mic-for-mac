import SwiftUI
import Supabase

struct ConfigurationValidationView: View {
    @StateObject private var configValidator = ConfigurationValidator()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Configuration Check")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Verify your Supabase setup")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Configuration Status
                VStack(spacing: 16) {
                    ConfigurationStatusCard(
                        title: "Environment Variables",
                        status: configValidator.environmentStatus,
                        description: "Supabase URL and API Key"
                    )
                    
                    ConfigurationStatusCard(
                        title: "Supabase Connection",
                        status: configValidator.connectionStatus,
                        description: "Database connectivity"
                    )
                    
                    ConfigurationStatusCard(
                        title: "Authentication",
                        status: configValidator.authStatus,
                        description: "User authentication system"
                    )
                }
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Run Full Validation") {
                        Task {
                            await configValidator.runFullValidation()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(configValidator.isValidating)
                    
                    if configValidator.isValidating {
                        ProgressView("Validating...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    
                    Button("Open Setup Guide") {
                        openSetupGuide()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Error Messages
                if !configValidator.errorMessages.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Issues Found:")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        ForEach(configValidator.errorMessages, id: \.self) { message in
                            Text("• \(message)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Setup Validation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await configValidator.runFullValidation()
            }
        }
    }
    
    private func openSetupGuide() {
        if let url = URL(string: "https://github.com/your-repo/mic-for-mac/blob/main/SUPABASE_SETUP.md") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct ConfigurationStatusCard: View {
    let title: String
    let status: ConfigurationValidator.Status
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: status.icon)
                .foregroundColor(status.color)
                .font(.title2)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

class ConfigurationValidator: ObservableObject {
    enum Status {
        case pending
        case success
        case error
        case warning
        
        var icon: String {
            switch self {
            case .pending:
                return "clock"
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "xmark.circle.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .pending:
                return .gray
            case .success:
                return .green
            case .error:
                return .red
            case .warning:
                return .orange
            }
        }
    }
    
    @Published var environmentStatus: Status = .pending
    @Published var connectionStatus: Status = .pending
    @Published var authStatus: Status = .pending
    @Published var isValidating = false
    @Published var errorMessages: [String] = []
    
    func runFullValidation() async {
        await MainActor.run {
            isValidating = true
            errorMessages.removeAll()
        }
        
        // Check environment variables
        await validateEnvironment()
        
        // Check Supabase connection
        await validateConnection()
        
        // Check authentication
        await validateAuthentication()
        
        await MainActor.run {
            isValidating = false
        }
    }
    
    private func validateEnvironment() async {
        do {
            try SupabaseConfig.shared.validateConfiguration()
            await MainActor.run {
                environmentStatus = .success
            }
        } catch {
            await MainActor.run {
                environmentStatus = .error
                errorMessages.append("Environment configuration error: \(error.localizedDescription)")
            }
        }
    }
    
    private func validateConnection() async {
        guard environmentStatus == .success else {
            await MainActor.run {
                connectionStatus = .error
            }
            return
        }
        
        do {
            let client = SupabaseConfig.shared.client
            // Try a simple query to test connection
            let _: [String: Any] = try await client.database
                .from("user_profiles")
                .select("id")
                .limit(1)
                .execute()
                .value
            
            await MainActor.run {
                connectionStatus = .success
            }
        } catch {
            await MainActor.run {
                connectionStatus = .error
                errorMessages.append("Database connection failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func validateAuthentication() async {
        guard connectionStatus == .success else {
            await MainActor.run {
                authStatus = .error
            }
            return
        }
        
        do {
            let client = SupabaseConfig.shared.client
            let session = try await client.auth.session
            
            await MainActor.run {
                if session != nil {
                    authStatus = .success
                } else {
                    authStatus = .warning
                    errorMessages.append("No active session - authentication required")
                }
            }
        } catch {
            await MainActor.run {
                authStatus = .error
                errorMessages.append("Authentication system error: \(error.localizedDescription)")
            }
        }
    }
}

struct ConfigurationValidationView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurationValidationView()
    }
} 