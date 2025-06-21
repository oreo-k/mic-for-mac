import Foundation

struct AudioFile: Identifiable, Codable {
    let id = UUID()
    let url: URL
    let filename: String
    let date: Date
    let duration: TimeInterval
    let transcript: String
    let summary: String
    let conversationType: ConversationType
    let language: Language
    let transcriptionCost: Double
    let summarizationCost: Double
    let tokenCount: Int
    
    var totalCost: Double {
        transcriptionCost + summarizationCost
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedCost: String {
        String(format: "$%.4f", totalCost)
    }
    
    var formattedTranscriptionCost: String {
        String(format: "$%.4f", transcriptionCost)
    }
    
    var formattedSummarizationCost: String {
        String(format: "$%.4f", summarizationCost)
    }
} 