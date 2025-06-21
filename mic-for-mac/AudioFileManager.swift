import Foundation
import Combine

class AudioFileManager: ObservableObject {
    @Published var audioFiles: [AudioFile] = []
    
    struct AudioFile: Identifiable {
        let id = UUID()
        let url: URL
        let name: String
        let dateCreated: Date
        let fileSize: Int64
        let duration: TimeInterval? // Duration in seconds
        let transcriptionCost: Double? // Cost in USD
        let summarizationCost: Double? // Cost in USD
        let transcript: String? // Full transcript text
        let summary: String? // Full summary text
        let conversationType: ConversationType? // Type of conversation
        
        init(url: URL) {
            self.url = url
            self.name = url.lastPathComponent
            self.dateCreated = (try? FileManager.default.attributesOfItem(atPath: url.path)[.creationDate] as? Date) ?? Date()
            self.fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
            
            // Try to get data from UserDefaults (stored when processing)
            let fileKey = url.lastPathComponent
            self.duration = UserDefaults.standard.object(forKey: "duration_\(fileKey)") as? TimeInterval
            self.transcriptionCost = UserDefaults.standard.object(forKey: "transcription_cost_\(fileKey)") as? Double
            self.summarizationCost = UserDefaults.standard.object(forKey: "summarization_cost_\(fileKey)") as? Double
            self.transcript = UserDefaults.standard.string(forKey: "transcript_\(fileKey)")
            self.summary = UserDefaults.standard.string(forKey: "summary_\(fileKey)")
            
            // Get conversation type
            if let typeString = UserDefaults.standard.string(forKey: "conversation_type_\(fileKey)") {
                self.conversationType = ConversationType(rawValue: typeString)
            } else {
                self.conversationType = nil
            }
        }
        
        var totalCost: Double {
            (transcriptionCost ?? 0) + (summarizationCost ?? 0)
        }
        
        var hasCostData: Bool {
            transcriptionCost != nil || summarizationCost != nil
        }
        
        var hasTranscript: Bool {
            transcript != nil && !transcript!.isEmpty
        }
        
        var hasSummary: Bool {
            summary != nil && !summary!.isEmpty
        }
    }
    
    init() {
        loadAudioFiles()
    }
    
    func loadAudioFiles() {
        let tempDirectory = FileManager.default.temporaryDirectory
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey], options: [])
            audioFiles = fileURLs
                .filter { $0.pathExtension == "m4a" }
                .map { AudioFile(url: $0) }
                .sorted { $0.dateCreated > $1.dateCreated }
        } catch {
            print("Error loading audio files: \(error)")
            audioFiles = []
        }
    }
    
    func deleteAudioFile(_ audioFile: AudioFile) {
        do {
            // Clean up all stored data
            let fileKey = audioFile.url.lastPathComponent
            UserDefaults.standard.removeObject(forKey: "duration_\(fileKey)")
            UserDefaults.standard.removeObject(forKey: "transcription_cost_\(fileKey)")
            UserDefaults.standard.removeObject(forKey: "summarization_cost_\(fileKey)")
            UserDefaults.standard.removeObject(forKey: "transcript_\(fileKey)")
            UserDefaults.standard.removeObject(forKey: "summary_\(fileKey)")
            UserDefaults.standard.removeObject(forKey: "conversation_type_\(fileKey)")
            
            try FileManager.default.removeItem(at: audioFile.url)
            loadAudioFiles() // Reload the list
        } catch {
            print("Error deleting audio file: \(error)")
        }
    }
    
    func deleteAllAudioFiles() {
        for audioFile in audioFiles {
            deleteAudioFile(audioFile)
        }
    }
    
    // MARK: - Processing Data Storage
    func saveProcessingData(for audioURL: URL, duration: TimeInterval, transcriptionCost: Double, summarizationCost: Double, transcript: String, summary: String, conversationType: ConversationType) {
        let fileKey = audioURL.lastPathComponent
        UserDefaults.standard.set(duration, forKey: "duration_\(fileKey)")
        UserDefaults.standard.set(transcriptionCost, forKey: "transcription_cost_\(fileKey)")
        UserDefaults.standard.set(summarizationCost, forKey: "summarization_cost_\(fileKey)")
        UserDefaults.standard.set(transcript, forKey: "transcript_\(fileKey)")
        UserDefaults.standard.set(summary, forKey: "summary_\(fileKey)")
        UserDefaults.standard.set(conversationType.rawValue, forKey: "conversation_type_\(fileKey)")
        
        // Reload to update the UI
        loadAudioFiles()
    }
    
    // MARK: - Cost Calculation
    func calculateTranscriptionCost(durationMinutes: Double) -> Double {
        // Whisper API pricing: $0.006 per minute
        return durationMinutes * 0.006
    }
    
    func calculateSummarizationCost(tokenCount: Int) -> Double {
        // GPT-3.5-turbo pricing: $0.002 per 1K tokens (input + output)
        return Double(tokenCount) * 0.002 / 1000.0
    }
    
    // MARK: - Formatting
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func formatCost(_ cost: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 4
        return formatter.string(from: NSNumber(value: cost)) ?? "$0.0000"
    }
    
    func formatTotalCost(_ cost: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: cost)) ?? "$0.00"
    }
    
    // MARK: - Statistics
    var totalCost: Double {
        audioFiles.reduce(0) { $0 + $1.totalCost }
    }
    
    var totalDuration: TimeInterval {
        audioFiles.reduce(0) { $0 + ($1.duration ?? 0) }
    }
    
    var filesWithCostData: Int {
        audioFiles.filter { $0.hasCostData }.count
    }
    
    var filesWithTranscript: Int {
        audioFiles.filter { $0.hasTranscript }.count
    }
} 