import SwiftUI

struct AudioFileManagementView: View {
    @StateObject private var audioFileManager = AudioFileManager()
    @State private var showingDeleteAllAlert = false
    @State private var showingDeleteAlert = false
    @State private var audioFileToDelete: AudioFileManager.AudioFile?
    @State private var expandedFiles: Set<String> = []
    
    var body: some View {
        NavigationView {
            VStack {
                if audioFileManager.audioFiles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "waveform")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No recorded audio files")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Record some audio to see files here")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        // Cost Summary Section
                        if audioFileManager.filesWithCostData > 0 {
                            CostSummaryView(audioFileManager: audioFileManager)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                        }
                        
                        // Files List
                        List {
                            ForEach(audioFileManager.audioFiles) { audioFile in
                                AudioFileRow(
                                    audioFile: audioFile, 
                                    audioFileManager: audioFileManager,
                                    isExpanded: expandedFiles.contains(audioFile.name)
                                ) {
                                    // Toggle expansion
                                    if expandedFiles.contains(audioFile.name) {
                                        expandedFiles.remove(audioFile.name)
                                    } else {
                                        expandedFiles.insert(audioFile.name)
                                    }
                                } onDelete: {
                                    audioFileToDelete = audioFile
                                    showingDeleteAlert = true
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Audio Files")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete All") {
                        showingDeleteAllAlert = true
                    }
                    .disabled(audioFileManager.audioFiles.isEmpty)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Refresh") {
                        audioFileManager.loadAudioFiles()
                    }
                }
            }
            .alert("Delete All Files", isPresented: $showingDeleteAllAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    audioFileManager.deleteAllAudioFiles()
                }
            } message: {
                Text("Are you sure you want to delete all recorded audio files? This action cannot be undone.")
            }
            .alert("Delete File", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let audioFile = audioFileToDelete {
                        audioFileManager.deleteAudioFile(audioFile)
                    }
                }
            } message: {
                if let audioFile = audioFileToDelete {
                    Text("Are you sure you want to delete '\(audioFile.name)'? This action cannot be undone.")
                }
            }
        }
        .onAppear {
            audioFileManager.loadAudioFiles()
        }
    }
}

struct CostSummaryView: View {
    let audioFileManager: AudioFileManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.green)
                Text("Cost Summary")
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Cost")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(audioFileManager.formatTotalCost(audioFileManager.totalCost))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Files Processed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(audioFileManager.filesWithCostData)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(audioFileManager.formatDuration(audioFileManager.totalDuration))
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
        }
    }
}

struct AudioFileRow: View {
    let audioFile: AudioFileManager.AudioFile
    let audioFileManager: AudioFileManager
    let isExpanded: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with file info and actions
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(audioFile.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack {
                        Text(audioFileManager.formatDate(audioFile.dateCreated))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(audioFileManager.formatFileSize(audioFile.fileSize))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let duration = audioFile.duration {
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text(audioFileManager.formatDuration(duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Expand/Collapse button
                    if audioFile.hasTranscript || audioFile.hasSummary {
                        Button(action: onToggle) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Cost Information
            if audioFile.hasCostData {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "dollarsign.circle")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("API Costs")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        Spacer()
                    }
                    
                    HStack(spacing: 16) {
                        if let transcriptionCost = audioFile.transcriptionCost {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Transcription")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(audioFileManager.formatCost(transcriptionCost))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if let summarizationCost = audioFile.summarizationCost {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Summarization")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(audioFileManager.formatCost(summarizationCost))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Total")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(audioFileManager.formatCost(audioFile.totalCost))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.top, 4)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(6)
            }
            
            // Expandable Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Transcript Section
                    if let transcript = audioFile.transcript, !transcript.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "text.bubble")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text("Transcript")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            
                            Text(transcript)
                                .font(.body)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Summary Section
                    if let summary = audioFile.summary, !summary.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.purple)
                                    .font(.caption)
                                Text("Summary")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.purple)
                                Spacer()
                            }
                            
                            Text(summary)
                                .font(.body)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

struct AudioFileManagementView_Previews: PreviewProvider {
    static var previews: some View {
        AudioFileManagementView()
    }
} 