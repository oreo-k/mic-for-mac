import Foundation

class EnvironmentConfig {
    static let shared = EnvironmentConfig()
    
    private var environmentVariables: [String: String] = [:]
    
    private init() {
        loadEnvironmentVariables()
    }
    
    private func loadEnvironmentVariables() {
        // First, try to load from .env file
        if let envPath = Bundle.main.path(forResource: ".env", ofType: nil) {
            loadFromFile(path: envPath)
        }
        
        // Then override with actual environment variables
        for (key, value) in ProcessInfo.processInfo.environment {
            environmentVariables[key] = value
        }
    }
    
    private func loadFromFile(path: String) {
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedLine.isEmpty && !trimmedLine.hasPrefix("#") {
                    let components = trimmedLine.components(separatedBy: "=")
                    if components.count >= 2 {
                        let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        let value = components.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)
                        environmentVariables[key] = value
                    }
                }
            }
        } catch {
            print("Warning: Could not load .env file: \(error)")
        }
    }
    
    func get(_ key: String) -> String? {
        return environmentVariables[key]
    }
    
    func get(_ key: String, defaultValue: String) -> String {
        return environmentVariables[key] ?? defaultValue
    }
    
    // Convenience methods for specific keys
    var supabaseURL: String? {
        return get("SUPABASE_URL")
    }
    
    var supabaseAnonKey: String? {
        return get("SUPABASE_ANON_KEY")
    }
    
    var openAIAPIKey: String? {
        return get("OPENAI_API_KEY")
    }
} 