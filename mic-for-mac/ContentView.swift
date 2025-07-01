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
    @State private var isShowingProfile = false
    @State private var showingProcessingConfirmation = false
    @State private var pendingRecordingURL: URL?
    @State private var isProcessing = false
    @State private var showingProcessingAlert = false
    @State private var processingErrorMessage = ""
    
    // Veterinary consultation form state
    @State private var showingVeterinaryForm = false
    @State private var selectedDogsForConsultation: Set<UUID> = []
    @State private var visitPurpose: String = ""
    
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
        .sheet(isPresented: $isShowingProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showingVeterinaryForm) {
            VeterinaryConsultationForm { selectedDogs, purpose in
                selectedDogsForConsultation = selectedDogs
                visitPurpose = purpose
                // After form submission, start recording
                startRecording()
            }
        }
        .alert("Process Recording", isPresented: $showingProcessingConfirmation) {
            Button("Process Now") {
                Task {
                    await processRecording()
                }
            }
            Button("Save for Later", role: .cancel) {
                saveAsPending()
            }
        } message: {
            Text("Would you like to process this recording now with Whisper and ChatGPT? This will incur API costs. You can also save it for later processing.")
        }
        .alert("Processing Error", isPresented: $showingProcessingAlert) {
            Button("OK") { }
        } message: {
            Text(processingErrorMessage)
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
            } else if isProcessing {
                VStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .foregroundColor(.blue)
                    
                    Text("Processing Audio...")
                        .font(.headline)
                        .foregroundColor(.blue)
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
                    // Check if veterinary consultation form is needed
                    if selectedConversationType == .veterinary {
                        showingVeterinaryForm = true
                    } else {
                        startRecording()
                    }
                }
            }) {
                HStack(spacing: 10) {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: audioRecorder.isRecording ? "stop.fill" : "record.circle")
                            .font(.title2)
                    }
                    
                    Text(isProcessing ? "Processing..." : (
                        audioRecorder.isRecording ? "Stop Recording" : (
                            selectedConversationType == .veterinary ? "Set Up Veterinary Visit" : "Start Recording"
                        )
                    ))
                    .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(isProcessing ? Color.gray : (audioRecorder.isRecording ? Color.red : Color.blue))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isProcessing)
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
                isShowingProfile = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
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
        
        // Store the URL and show confirmation dialog
        pendingRecordingURL = recordingURL
        showingProcessingConfirmation = true
    }
    
    private func processRecording() async {
        guard let recordingURL = pendingRecordingURL else { return }
        
        isProcessing = true
        
        do {
            // Transcribe with Whisper
            let transcriptionResult = try await apiService.transcribeWithWhisper(
                audioURL: recordingURL,
                language: selectedLanguage
            )
            
            // Get profile information for enhanced summaries
            let profileManager = ProfileManager()
            let multiDogProfile = profileManager.multiDogProfile
            let multiOwnerProfile = profileManager.multiOwnerProfile
            
            // For veterinary consultations, filter to only selected dogs
            var filteredMultiDogProfile = multiDogProfile
            if selectedConversationType == .veterinary && !selectedDogsForConsultation.isEmpty {
                filteredMultiDogProfile = MultiDogProfile(
                    dogs: multiDogProfile.dogs.filter { selectedDogsForConsultation.contains($0.id) }
                )
            }
            
            // Summarize with GPT (including profile information and veterinary context)
            let summarizationResult = try await apiService.summarizeWithGPT(
                transcript: transcriptionResult.text,
                conversationType: selectedConversationType,
                language: selectedLanguage,
                multiDogProfile: filteredMultiDogProfile,
                multiOwnerProfile: multiOwnerProfile,
                veterinaryContext: selectedConversationType == .veterinary ? VeterinaryContext(
                    selectedDogs: selectedDogsForConsultation,
                    visitPurpose: visitPurpose
                ) : nil
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
                tokenCount: summarizationResult.tokenCount,
                veterinaryContext: selectedConversationType == .veterinary ? VeterinaryContext(
                    selectedDogs: selectedDogsForConsultation,
                    visitPurpose: visitPurpose
                ) : nil
            )
            
            fileManager.addFile(audioFile)
            
            // Clear the pending URL and veterinary context
            pendingRecordingURL = nil
            selectedDogsForConsultation = []
            visitPurpose = ""
            
        } catch {
            processingErrorMessage = error.localizedDescription
            showingProcessingAlert = true
        }
        
        isProcessing = false
    }
    
    private func saveAsPending() {
        guard let recordingURL = pendingRecordingURL else { return }
        
        // Create a pending audio file
        let pendingFile = AudioFile(
            url: recordingURL,
            filename: recordingURL.lastPathComponent,
            date: Date(),
            duration: 0.0, // We'll get the actual duration when processing
            conversationType: selectedConversationType,
            language: selectedLanguage,
            veterinaryContext: selectedConversationType == .veterinary ? VeterinaryContext(
                selectedDogs: selectedDogsForConsultation,
                visitPurpose: visitPurpose
            ) : nil
        )
        
        fileManager.addFile(pendingFile)
        
        // Clear the pending URL and veterinary context
        pendingRecordingURL = nil
        selectedDogsForConsultation = []
        visitPurpose = ""
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
