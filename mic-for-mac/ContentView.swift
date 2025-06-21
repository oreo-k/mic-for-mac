//
//  ContentView.swift
//  mic-for-mac
//
//  Created by Reo Kosaka on 6/17/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var apiService = APIService()
    @StateObject private var fileManager = AudioFileManager()
    
    @State private var selectedConversationType: ConversationType = .personal
    @State private var selectedLanguage: Language = .english
    @State private var isShowingFileManager = false
    @State private var isShowingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                headerSection
                languageSelectionSection
                conversationTypeSection
                recordingStatusSection
                recordingControlsSection
                Spacer()
                bottomButtonsSection
            }
            .padding()
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $isShowingFileManager) {
            AudioFileManagementView()
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
    }
    
    // MARK: - UI Sections
    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("Mic for Mac")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Record and summarize conversations")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var languageSelectionSection: some View {
        VStack(spacing: 15) {
            Text("Language")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                ForEach(Language.allCases) { language in
                    Button(action: {
                        selectedLanguage = language
                    }) {
                        VStack(spacing: 8) {
                            Text(language.flag)
                                .font(.title)
                            
                            Text(language.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(width: 80, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedLanguage == language ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedLanguage == language ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var conversationTypeSection: some View {
        VStack(spacing: 15) {
            Text("Conversation Type")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(ConversationType.allCases) { type in
                        Button(action: {
                            selectedConversationType = type
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: type.icon)
                                    .font(.title2)
                                    .foregroundColor(selectedConversationType == type ? .white : .blue)
                                
                                Text(type.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedConversationType == type ? .white : .primary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 100, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedConversationType == type ? Color.blue : Color.gray.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
            
            Text(selectedConversationType.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var recordingStatusSection: some View {
        VStack(spacing: 15) {
            if audioRecorder.isRecording {
                VStack(spacing: 10) {
                    Image(systemName: "waveform")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                        .scaleEffect(audioRecorder.isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: audioRecorder.isRecording)
                    
                    Text("Recording...")
                        .font(.headline)
                        .foregroundColor(.red)
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Ready to Record")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    private var recordingControlsSection: some View {
        VStack(spacing: 20) {
            Button(action: {
                if audioRecorder.isRecording {
                    Task {
                        await stopRecording()
                    }
                } else {
                    startRecording()
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: audioRecorder.isRecording ? "stop.fill" : "record.circle")
                        .font(.title2)
                    
                    Text(audioRecorder.isRecording ? "Stop Recording" : "Start Recording")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(audioRecorder.isRecording ? Color.red : Color.blue)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var bottomButtonsSection: some View {
        HStack(spacing: 20) {
            Button(action: {
                isShowingFileManager = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "folder.fill")
                    Text("Files")
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.blue, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                isShowingSettings = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.blue, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Actions
    private func startRecording() {
        audioRecorder.startRecording()
    }
    
    private func stopRecording() async {
        audioRecorder.stopRecording()
        
        // Get the recording URL
        guard let recordingURL = audioRecorder.getAudioFileURL() else { return }
        
        do {
            // Transcribe with Whisper
            let transcriptionResult = try await apiService.transcribeWithWhisper(
                audioURL: recordingURL,
                language: selectedLanguage
            )
            
            // Summarize with GPT
            let summarizationResult = try await apiService.summarizeWithGPT(
                transcript: transcriptionResult.text,
                conversationType: selectedConversationType,
                language: selectedLanguage
            )
            
            // Save file with metadata
            let audioFile = AudioFile(
                url: recordingURL,
                filename: recordingURL.lastPathComponent,
                date: Date(),
                duration: transcriptionResult.duration,
                transcript: transcriptionResult.text,
                summary: summarizationResult.text,
                conversationType: selectedConversationType,
                language: selectedLanguage,
                transcriptionCost: transcriptionResult.cost,
                summarizationCost: summarizationResult.cost,
                tokenCount: summarizationResult.tokenCount
            )
            
            fileManager.addFile(audioFile)
            
        } catch {
            print("Error processing recording: \(error)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
