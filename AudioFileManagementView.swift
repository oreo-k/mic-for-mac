import SwiftUI

struct AudioFileManagementView: View {
    @StateObject private var audioFileManager = AudioFileManager()
    @State private var showingDeleteAllAlert = false
    @State private var showingDeleteAlert = false
    @State private var audioFileToDelete: AudioFileManager.AudioFile?
    
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
                    List {
                        ForEach(audioFileManager.audioFiles) { audioFile in
                            AudioFileRow(audioFile: audioFile) {
                                audioFileToDelete = audioFile
                                showingDeleteAlert = true
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

struct AudioFileRow: View {
    let audioFile: AudioFileManager.AudioFile
    let onDelete: () -> Void
    
    var body: some View {
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
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
    
    private var audioFileManager: AudioFileManager {
        AudioFileManager()
    }
}

struct AudioFileManagementView_Previews: PreviewProvider {
    static var previews: some View {
        AudioFileManagementView()
    }
} 