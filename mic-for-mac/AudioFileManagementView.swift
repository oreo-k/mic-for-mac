import SwiftUI

struct AudioFileManagementView: View {
    @StateObject private var fileManager = AudioFileManager()
    @Environment(\.dismiss) private var dismiss
    
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
                    List {
                        ForEach(fileManager.audioFiles) { audioFile in
                            AudioFileRow(audioFile: audioFile)
                        }
                        .onDelete(perform: deleteFiles)
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
        }
    }
    
    private func deleteFiles(offsets: IndexSet) {
        fileManager.deleteFiles(at: offsets)
    }
}

struct AudioFileRow: View {
    let audioFile: AudioFile
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(audioFile.filename)
                        .font(.headline)
                        .lineLimit(1)
                    
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
                        .foregroundColor(.blue)
                    
                    Text("\(audioFile.tokenCount) tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
            
            // Expandable Content
            if isExpanded {
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
            
            // Expand/Collapse Button
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
        .padding(.vertical, 8)
    }
}

struct AudioFileManagementView_Previews: PreviewProvider {
    static var previews: some View {
        AudioFileManagementView()
    }
} 