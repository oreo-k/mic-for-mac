import SwiftUI

struct AudioFileManagementView: View {
    @StateObject private var fileManager = AudioFileManager()
    @StateObject private var apiService = APIService()
    @Environment(\.dismiss) private var dismiss
    @State private var processingFileId: UUID?
    @State private var showingProcessingAlert = false
    @State private var processingErrorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if fileManager.audioFiles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "folder")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No recordings yet")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Your recordings will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Summary Section
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Files")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(fileManager.audioFiles.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 4) {
                                Text("Processed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(fileManager.processedFilesCount)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Pending")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(fileManager.pendingFilesCount)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        if fileManager.processedFilesCount > 0 {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Cost")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(fileManager.formatTotalCost())
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Total Duration")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(fileManager.formatTotalDuration())
                                        .font(.title3)
                                        .fontWeight(.bold)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    List {
                        ForEach(Array(fileManager.audioFiles.enumerated()), id: \ .element.id) { index, audioFile in
                            AudioFileRow(
                                audioFile: audioFile,
                                onProcess: { processAudioFile(audioFile) },
                                isProcessing: processingFileId == audioFile.id,
                                onDelete: { deleteFile(at: index) }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Recordings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") {
                        fileManager.clearAllFiles()
                    }
                    .foregroundColor(.red)
                }
            }
            .alert("Processing Error", isPresented: $showingProcessingAlert) {
                Button("OK") { }
            } message: {
                Text(processingErrorMessage)
            }
        }
    }
    
    private func deleteFile(at index: Int) {
        fileManager.deleteFiles(at: IndexSet(integer: index))
    }
    
    private func processAudioFile(_ audioFile: AudioFile) {
        guard audioFile.isPending else { return }
        
        processingFileId = audioFile.id
        
        Task {
            do {
                // Get actual audio duration
                let actualDuration = try await apiService.getAudioDuration(from: audioFile.url)
                
                // Transcribe with Whisper
                let transcriptionResult = try await apiService.transcribeWithWhisper(
                    audioURL: audioFile.url,
                    language: audioFile.language
                )
                
                // Get profile information for enhanced summaries
                let profileManager = ProfileManager()
                let dogProfile = profileManager.dogProfile
                let ownerProfile = profileManager.ownerProfile
                
                // Summarize with GPT (including profile information)
                let summarizationResult = try await apiService.summarizeWithGPT(
                    transcript: transcriptionResult.text,
                    conversationType: audioFile.conversationType,
                    language: audioFile.language,
                    dogProfile: dogProfile,
                    ownerProfile: ownerProfile
                )
                
                // Create processed file
                let processedFile = AudioFile(
                    url: audioFile.url,
                    filename: audioFile.filename,
                    date: audioFile.date,
                    duration: actualDuration,
                    transcript: transcriptionResult.text,
                    summary: summarizationResult.text,
                    conversationType: audioFile.conversationType,
                    language: audioFile.language,
                    transcriptionCost: transcriptionResult.cost,
                    summarizationCost: summarizationResult.cost,
                    tokenCount: summarizationResult.tokenCount
                )
                
                // Update the file in the manager
                await MainActor.run {
                    fileManager.updatePendingFile(with: processedFile)
                    processingFileId = nil
                }
                
            } catch {
                await MainActor.run {
                    processingErrorMessage = error.localizedDescription
                    showingProcessingAlert = true
                    processingFileId = nil
                }
            }
        }
    }
}

struct AudioFileRow: View {
    let audioFile: AudioFile
    let onProcess: () -> Void
    let isProcessing: Bool
    let onDelete: () -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(audioFile.filename)
                            .font(.headline)
                            .lineLimit(1)
                        
                        if audioFile.isPending {
                            Text("PENDING")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Label(audioFile.formattedDate, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label(audioFile.formattedDuration, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(audioFile.formattedCost)
                        .font(.headline)
                        .foregroundColor(audioFile.isPending ? .orange : .blue)
                    
                    if !audioFile.isPending {
                        Text("\(audioFile.tokenCount) tokens")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Trash button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading, 8)
            }
            
            // Conversation Type and Language
            HStack(spacing: 12) {
                Label(audioFile.conversationType.displayName, systemImage: audioFile.conversationType.icon)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                Label(audioFile.language.displayName, systemImage: "globe")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Process Button for Pending Files
            if audioFile.isPending {
                Button(action: onProcess) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.circle.fill")
                        }
                        Text(isProcessing ? "Processing..." : "Process Audio")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isProcessing ? Color.gray : Color.blue)
                    )
                }
                .disabled(isProcessing)
                .buttonStyle(PlainButtonStyle())
            }
            
            // Expandable Content (only for processed files)
            if !audioFile.isPending && isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // Cost Breakdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cost Breakdown")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text("Transcription:")
                            Spacer()
                            Text(audioFile.formattedTranscriptionCost)
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                        
                        HStack {
                            Text("Summarization:")
                            Spacer()
                            Text(audioFile.formattedSummarizationCost)
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Transcript
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transcript")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(audioFile.transcript)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    
                    // Summary
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(audioFile.summary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                }
            }
            
            // Expand/Collapse Button (only for processed files)
            if !audioFile.isPending {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text(isExpanded ? "Show Less" : "Show More")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
    }
}

struct AudioFileManagementView_Previews: PreviewProvider {
    static var previews: some View {
        AudioFileManagementView()
    }
} 