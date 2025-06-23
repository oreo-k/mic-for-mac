import Foundation

class APIService: ObservableObject {
    // MARK: - Configuration
    private var whisperAPIKey: String {
        // Try to get from environment variable first
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return envKey
        }
        // Fallback to UserDefaults (for development)
        return UserDefaults.standard.string(forKey: "OPENAI_API_KEY") ?? ""
    }
    
    private let whisperURL = "https://api.openai.com/v1/audio/transcriptions"
    private let gptURL = "https://api.openai.com/v1/chat/completions"
    
    // MARK: - Response Types
    struct TranscriptionResult {
        let text: String
        let cost: Double
        let duration: TimeInterval
    }
    
    struct SummarizationResult {
        let text: String
        let cost: Double
        let tokenCount: Int
    }
    
    // MARK: - Whisper Transcription
    func transcribeWithWhisper(audioURL: URL, language: Language) async throws -> TranscriptionResult {
        guard !whisperAPIKey.isEmpty else {
            throw APIError.missingAPIKey
        }
        
        // Get audio duration for cost calculation
        let duration = try await getAudioDuration(from: audioURL)
        let durationMinutes = duration / 60.0
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: whisperURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(whisperAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(audioURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(try Data(contentsOf: audioURL))
        body.append("\r\n".data(using: .utf8)!)
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add language parameter based on selected language
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(language.rawValue)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        let whisperResponse = try JSONDecoder().decode(WhisperResponse.self, from: data)
        
        // Calculate cost: $0.006 per minute
        let cost = durationMinutes * 0.006
        
        return TranscriptionResult(text: whisperResponse.text, cost: cost, duration: duration)
    }
    
    // MARK: - GPT Summarization
    func summarizeWithGPT(transcript: String, conversationType: ConversationType, language: Language) async throws -> SummarizationResult {
        guard !whisperAPIKey.isEmpty else {
            throw APIError.missingAPIKey
        }
        
        // Use the appropriate prompt based on conversation type and language
        let prompt = conversationType.userPrompt(language: language).replacingOccurrences(of: "{transcript}", with: transcript)
        
        let requestBody = GPTRequest(
            model: "gpt-3.5-turbo",
            messages: [
                GPTMessage(role: "system", content: conversationType.systemPrompt(language: language)),
                GPTMessage(role: "user", content: prompt)
            ],
            max_tokens: 500,
            temperature: 0.3
        )
        
        var request = URLRequest(url: URL(string: gptURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(whisperAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        let gptResponse = try JSONDecoder().decode(GPTResponse.self, from: data)
        
        // Calculate cost based on token usage
        let totalTokens = gptResponse.usage.total_tokens
        let cost = Double(totalTokens) * 0.002 / 1000.0 // $0.002 per 1K tokens
        
        return SummarizationResult(
            text: gptResponse.choices.first?.message.content ?? "No summary generated",
            cost: cost,
            tokenCount: totalTokens
        )
    }
    
    // MARK: - Helper Methods
    func getAudioDuration(from url: URL) async throws -> TimeInterval {
        // For now, we'll estimate duration based on file size
        // In a production app, you might want to use AVAsset to get exact duration
        let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
        
        // Rough estimation: 1MB ≈ 1 minute of audio at typical quality
        let estimatedDuration = Double(fileSize) / (1024 * 1024) * 60
        
        return estimatedDuration
    }
}

// MARK: - Response Models
struct WhisperResponse: Codable {
    let text: String
}

struct GPTRequest: Codable {
    let model: String
    let messages: [GPTMessage]
    let max_tokens: Int
    let temperature: Double
}

struct GPTMessage: Codable {
    let role: String
    let content: String
}

struct GPTResponse: Codable {
    let choices: [GPTChoice]
    let usage: GPTUsage
}

struct GPTChoice: Codable {
    let message: GPTMessage
}

struct GPTUsage: Codable {
    let total_tokens: Int
}

// MARK: - Error Types
enum APIError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case serverError(Int, String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is missing. Please set OPENAI_API_KEY environment variable or add it in UserDefaults."
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code, let message):
            return "Server error \(code): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
} 