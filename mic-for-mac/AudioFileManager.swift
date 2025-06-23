import Foundation
import SwiftUI

class AudioFileManager: ObservableObject {
    @Published var audioFiles: [AudioFile] = []
    
    private let userDefaults = UserDefaults.standard
    private let audioFilesKey = "audioFiles"
    
    init() {
        loadAudioFiles()
    }
    
    func addFile(_ audioFile: AudioFile) {
        audioFiles.append(audioFile)
        saveAudioFiles()
    }
    
    func updatePendingFile(with processedFile: AudioFile) {
        if let index = audioFiles.firstIndex(where: { $0.id == processedFile.id }) {
            audioFiles[index] = processedFile
            saveAudioFiles()
        }
    }
    
    func deleteFiles(at offsets: IndexSet) {
        // Delete the actual files from disk
        for index in offsets {
            let audioFile = audioFiles[index]
            try? FileManager.default.removeItem(at: audioFile.url)
        }
        
        // Remove from array
        audioFiles.remove(atOffsets: offsets)
        saveAudioFiles()
    }
    
    func clearAllFiles() {
        // Delete all files from disk
        for audioFile in audioFiles {
            try? FileManager.default.removeItem(at: audioFile.url)
        }
        
        // Clear array
        audioFiles.removeAll()
        saveAudioFiles()
    }
    
    private func loadAudioFiles() {
        guard let data = userDefaults.data(forKey: audioFilesKey),
              let files = try? JSONDecoder().decode([AudioFile].self, from: data) else {
            return
        }
        
        // Filter out files that no longer exist on disk
        audioFiles = files.filter { FileManager.default.fileExists(atPath: $0.url.path) }
        
        // If any files were removed, save the updated list
        if audioFiles.count != files.count {
            saveAudioFiles()
        }
    }
    
    private func saveAudioFiles() {
        guard let data = try? JSONEncoder().encode(audioFiles) else { return }
        userDefaults.set(data, forKey: audioFilesKey)
    }
    
    // MARK: - Statistics
    var totalCost: Double {
        audioFiles.filter { !$0.isPending }.reduce(0) { $0 + $1.totalCost }
    }
    
    var totalDuration: TimeInterval {
        audioFiles.reduce(0) { $0 + $1.duration }
    }
    
    var totalTokenCount: Int {
        audioFiles.filter { !$0.isPending }.reduce(0) { $0 + $1.tokenCount }
    }
    
    var pendingFilesCount: Int {
        audioFiles.filter { $0.isPending }.count
    }
    
    var processedFilesCount: Int {
        audioFiles.filter { !$0.isPending }.count
    }
    
    var filesByLanguage: [Language: Int] {
        Dictionary(grouping: audioFiles, by: { $0.language })
            .mapValues { $0.count }
    }
    
    var filesByConversationType: [ConversationType: Int] {
        Dictionary(grouping: audioFiles, by: { $0.conversationType })
            .mapValues { $0.count }
    }
    
    // MARK: - Formatting
    func formatTotalCost() -> String {
        String(format: "$%.4f", totalCost)
    }
    
    func formatTotalDuration() -> String {
        let hours = Int(totalDuration) / 3600
        let minutes = Int(totalDuration) % 3600 / 60
        let seconds = Int(totalDuration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
} 