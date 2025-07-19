import Foundation

class EnvironmentConfig {
    static let shared = EnvironmentConfig()
    
    private var environmentVariables: [String: String] = [:]
    
    private init() {
        loadEnvironmentVariables()
    }
    
    private func loadEnvironmentVariables() {
        print("🔧 Loading environment variables...")
        
        // First, try to load from .env file
        if let envPath = Bundle.main.path(forResource: ".env", ofType: nil) {
            print("📁 Found .env file at: \(envPath)")
            loadFromFile(path: envPath)
        } else {
            print("⚠️ No .env file found in app bundle")
        }
        
        // Then override with actual environment variables
        print("🌍 Loading from ProcessInfo.environment...")
        for (key, value) in ProcessInfo.processInfo.environment {
            if key.contains("SUPABASE") || key.contains("OPENAI") {
                print("  \(key): \(value.prefix(10))...")
            }
            environmentVariables[key] = value
        }
        
        print("📊 Final environment variables:")
        print("  SUPABASE_URL: \(supabaseURL ?? "nil")")
        print("  SUPABASE_ANON_KEY: \(supabaseAnonKey?.prefix(20) ?? "nil")...")
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