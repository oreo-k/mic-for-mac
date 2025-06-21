//
//  ContentView.swift
//  mic-for-mac
//
//  Created by Reo Kosaka on 6/17/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var summary: String = ""
    @State private var transcript: String = ""
    @State private var showingFileManagement = false
    
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
                    Text("Generate Summary")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(audioRecorder.isRecording || audioRecorder.getAudioFileURL() == nil)
                
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Manage Files") {
                        showingFileManagement = true
                    }
                }
            }
            .sheet(isPresented: $showingFileManagement) {
                AudioFileManagementView()
            }
        }
    }
    
    // MARK: - API Calls
    func generateSummary() async {
        guard let audioURL = audioRecorder.getAudioFileURL() else { return }
        // 1. Send to Whisper API
        if let transcriptText = await transcribeWithWhisper(audioURL: audioURL) {
            transcript = transcriptText
            // 2. Send transcript to GPT API
            if let summaryText = await summarizeWithGPT(transcript: transcriptText) {
                summary = summaryText
            }
        }
    }
    
    func transcribeWithWhisper(audioURL: URL) async -> String? {
        // TODO: Replace with your actual Whisper API call
        // This is a placeholder for demonstration
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return "This is a mock transcript of the vet consultation."
    }
    
    func summarizeWithGPT(transcript: String) async -> String? {
        // TODO: Replace with your actual GPT API call
        // This is a placeholder for demonstration
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return "This is a mock summary of the consultation based on the transcript."
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
