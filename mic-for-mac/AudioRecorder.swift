import Foundation
import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?
    private var recordingURL: URL?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.record, mode: .measurement, options: [])
            try audioSession?.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).m4a")
        recordingURL = audioFilename
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            let success = audioRecorder?.record() ?? false
            if success {
                isRecording = true
                print("Recording started successfully at: \(audioFilename)")
            } else {
                print("Failed to start recording")
            }
        } catch {
            print("Could not start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        guard let recorder = audioRecorder else {
            print("No active recorder to stop")
            return
        }
        
        let wasRecording = recorder.isRecording
        recorder.stop()
        isRecording = false
        
        if wasRecording {
            print("Recording stopped. File saved at: \(recorder.url)")
        } else {
            print("Recording was not active when stop was called")
        }
    }
    
    func getAudioFileURL() -> URL? {
        return recordingURL
    }
    
    func getCurrentRecordingDuration() -> TimeInterval {
        return audioRecorder?.currentTime ?? 0.0
    }
    
    private func getDocumentsDirectory() -> URL {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsDir = docs.appendingPathComponent("mic-for-mac/Recordings", isDirectory: true)
        if !fileManager.fileExists(atPath: recordingsDir.path) {
            try? fileManager.createDirectory(at: recordingsDir, withIntermediateDirectories: true, attributes: nil)
        }
        return recordingsDir
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Recording finished successfully. Duration: \(recorder.currentTime) seconds")
        } else {
            print("Recording finished unsuccessfully")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Audio recorder encode error: \(error.localizedDescription)")
        }
    }
} 