//
//  ContentView.swift
//  mic-for-mac
//
//  Created by Reo Kosaka on 6/17/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var apiService = APIService()
    @StateObject private var audioFileManager = AudioFileManager()
    @State private var summary: String = ""
    @State private var transcript: String = ""
    @State private var showingFileManagement = false
    @State private var showingSettings = false
    @State private var isGeneratingSummary = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text(audioRecorder.isRecording ? "Recording..." : "Ready")
                    .font(.title)
                    .foregroundColor(audioRecorder.isRecording ? .red : .primary)
                    .padding()
                
                Button(action: {
                    if audioRecorder.isRecording {
                        audioRecorder.stopRecording()
                    } else {
                        audioRecorder.startRecording()
                    }
                }) {
                    Text(audioRecorder.isRecording ? "Stop Recording" : "Start Recording")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(audioRecorder.isRecording ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(audioRecorder.isRecording && audioRecorder.getAudioFileURL() == nil)
                
                Button(action: {
                    Task {
                        await generateSummary()
                    }
                }) {
                    HStack {
                        if isGeneratingSummary {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isGeneratingSummary ? "Generating..." : "Generate Summary")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(audioRecorder.isRecording || audioRecorder.getAudioFileURL() == nil || isGeneratingSummary)
                
                if !transcript.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transcript:")
                            .font(.headline)
                        Text(transcript)
                            .font(.body)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    .padding()
                }
                
                if !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary:")
                            .font(.headline)
                        Text(summary)
                            .font(.body)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    .padding()
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Mic for Mac")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Settings") {
                        showingSettings = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Manage Files") {
                        showingFileManagement = true
                    }
                }
            }
            .sheet(isPresented: $showingFileManagement) {
                AudioFileManagementView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    // MARK: - API Calls
    func generateSummary() async {
        guard let audioURL = audioRecorder.getAudioFileURL() else { return }
        
        await MainActor.run {
            isGeneratingSummary = true
            errorMessage = nil
        }
        
        do {
            // 1. Send to Whisper API
            let transcriptionResult = try await apiService.transcribeWithWhisper(audioURL: audioURL)
            
            await MainActor.run {
                transcript = transcriptionResult.text
            }
            
            // 2. Send transcript to GPT API
            let summarizationResult = try await apiService.summarizeWithGPT(transcript: transcriptionResult.text)
            
            await MainActor.run {
                summary = summarizationResult.text
                isGeneratingSummary = false
            }
            
            // 3. Save processing data (cost, transcript, summary, duration)
            audioFileManager.saveProcessingData(
                for: audioURL,
                duration: transcriptionResult.duration,
                transcriptionCost: transcriptionResult.cost,
                summarizationCost: summarizationResult.cost,
                transcript: transcriptionResult.text,
                summary: summarizationResult.text
            )
            
        } catch {
            await MainActor.run {
                isGeneratingSummary = false
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
