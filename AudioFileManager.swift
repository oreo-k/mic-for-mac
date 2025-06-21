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
        
        init(url: URL) {
            self.url = url
            self.name = url.lastPathComponent
            self.dateCreated = (try? FileManager.default.attributesOfItem(atPath: url.path)[.creationDate] as? Date) ?? Date()
            self.fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
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
} 