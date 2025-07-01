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
    let isPending: Bool
    let veterinaryContext: VeterinaryContext?
    
    // Initializer for processed files
    init(url: URL, filename: String, date: Date, duration: TimeInterval, transcript: String, summary: String, conversationType: ConversationType, language: Language, transcriptionCost: Double, summarizationCost: Double, tokenCount: Int, veterinaryContext: VeterinaryContext? = nil) {
        self.url = url
        self.filename = filename
        self.date = date
        self.duration = duration
        self.transcript = transcript
        self.summary = summary
        self.conversationType = conversationType
        self.language = language
        self.transcriptionCost = transcriptionCost
        self.summarizationCost = summarizationCost
        self.tokenCount = tokenCount
        self.isPending = false
        self.veterinaryContext = veterinaryContext
    }
    
    // Initializer for pending files (not yet processed)
    init(url: URL, filename: String, date: Date, duration: TimeInterval, conversationType: ConversationType, language: Language, veterinaryContext: VeterinaryContext? = nil) {
        self.url = url
        self.filename = filename
        self.date = date
        self.duration = duration
        self.transcript = ""
        self.summary = ""
        self.conversationType = conversationType
        self.language = language
        self.transcriptionCost = 0.0
        self.summarizationCost = 0.0
        self.tokenCount = 0
        self.isPending = true
        self.veterinaryContext = veterinaryContext
    }
    
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
        if isPending {
            return "Pending"
        }
        return String(format: "$%.4f", totalCost)
    }
    
    var formattedTranscriptionCost: String {
        if isPending {
            return "Pending"
        }
        return String(format: "$%.4f", transcriptionCost)
    }
    
    var formattedSummarizationCost: String {
        if isPending {
            return "Pending"
        }
        return String(format: "$%.4f", summarizationCost)
    }
    
    var hasVeterinaryContext: Bool {
        veterinaryContext != nil
    }
    
    var veterinaryContextDescription: String {
        veterinaryContext?.fullDescription ?? "No veterinary context"
    }
} 